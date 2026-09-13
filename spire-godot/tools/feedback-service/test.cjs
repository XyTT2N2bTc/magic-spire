// Offline contract tests: never contact Google and never send real email.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const properties = {};
const sent = [];
let remaining = 100, available = true, throwSend = false;
const sandbox = {
  ContentService: {MimeType: {JSON:'json'}, createTextOutput: text => ({text, setMimeType(){return this;}})},
  LockService: {getScriptLock: () => ({tryLock:()=>available, releaseLock(){}})},
  PropertiesService: {getScriptProperties: () => ({getProperty:k=>properties[k],setProperty:(k,v)=>properties[k]=v,
    getProperties:()=>({...properties}),deleteProperty:k=>delete properties[k]})},
  MailApp: {getRemainingDailyQuota:()=>remaining, sendEmail: mail=>{if(throwSend)throw Error('private diagnostic');sent.push(mail);}},
  Utilities: {DigestAlgorithm:{SHA_256:'sha256'},computeDigest:(alg,s)=>crypto.createHash(alg).update(s).digest(),
    base64Encode:b=>Buffer.from(b).toString('base64'),base64Decode:s=>Array.from(Buffer.from(s,'base64')),
    newBlob:(bytes,mime,name)=>({bytes,mime,name})}
};
vm.createContext(sandbox); vm.runInContext(fs.readFileSync(__dirname+'/Code.gs','utf8'),sandbox);
const valid = () => ({schema:1,id:crypto.randomBytes(16).toString('hex'),kind:'bug',title:'测试',description:'复现步骤',
  context:{version:'0.15',platform:'Windows',phase:'战斗',scene:'练习',floor:1,round:2,seed:42},logs:'',images:[]});
const post = p => JSON.parse(sandbox.doPost({postData:{contents:typeof p==='string'?p:JSON.stringify(p)}}).text);
let p = valid();p.images=[{data:Buffer.from([255,216,255,217]).toString('base64')}];p.to='other@example.com';
assert.equal(post(p).ok,true);assert.equal(sent.length,1);assert.equal(sent[0].to,'towerlover7787@gmail.com');
assert.equal(sent[0].attachments[0].mime,'image/jpeg');assert.equal(sent[0].attachments[0].name,'screenshot-1.jpg');
assert.equal(post(p).ok,true);assert.equal(sent.length,1);
p.title='改变原编号内容';assert.equal(post(p).code,'invalid');
assert.equal(post(valid()).code,'busy');
const invalids=[{title:''},{description:''},{title:'x\nBcc:evil'},{kind:'mail'},{id:'bad'},{images:[{data:'hello'}]},
  {images:Array(4).fill({data:''})},{context:{}},{description:'x'.repeat(4001)},{logs:22}];
for(const change of invalids) assert.equal(post({...valid(),...change}).code,'invalid');
assert.equal(post('{bad').code,'invalid');available=false;assert.equal(post(valid()).code,'busy');available=true;
remaining=0;assert.equal(post(valid()).code,'limited');remaining=100;
properties.usage=JSON.stringify({start:Date.now(),last:0,count:80});assert.equal(post(valid()).code,'limited');
delete properties.usage;throwSend=true;assert.equal(post(valid()).code,'unavailable');assert.equal(sent.length,1);
throwSend=false;delete properties.usage;p=valid();p.kind='suggestion';p.logs='玩家确认的日志';
assert.equal(post(p).ok,true);assert.match(sent[1].subject,/修改建议/);assert.match(sent[1].body,/玩家确认的日志/);
assert.equal(JSON.parse(sandbox.doGet().text).schema,1);
assert.equal(JSON.parse(sandbox.doGet({parameter:{receipt:p.id}}).text).id,p.id);
assert.equal(JSON.parse(sandbox.doGet({parameter:{receipt:'invalid'}}).text).code,'invalid');
assert.equal(JSON.parse(sandbox.doGet({parameter:{receipt:'0'.repeat(32)}}).text).code,'not_found');
console.log('Feedback service contract tests passed; no email sent.');
