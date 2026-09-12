"""Fix Godot 4.7.2 non-Gradle export's duplicate provider authorities.

The upstream exporter replaces every provider authority with .fileprovider.
Only AndroidX Startup's authority is repaired; all other manifest facts remain.
Output is unsigned and MUST be zipaligned and signed again by the caller.
"""
import argparse
import struct
import zipfile
from pathlib import Path


def u16(data, offset):
    return struct.unpack_from('<H', data, offset)[0]


def u32(data, offset):
    return struct.unpack_from('<I', data, offset)[0]


def fix_manifest(source):
    data = bytearray(source)
    if u16(data, 0) != 3 or u32(data, 4) != len(data):
        raise ValueError('Invalid Android binary XML')
    chunks = []
    pos = u16(data, 2)
    while pos < len(data):
        size = u32(data, pos + 4)
        if size < 8 or pos + size > len(data):
            raise ValueError('Invalid XML chunk bounds')
        chunks.append((u16(data, pos), pos, size))
        pos += size
    _, pool, pool_size = next(c for c in chunks if c[0] == 1)
    header_size = u16(data, pool + 2)
    count, style_count, flags, start, style_start = struct.unpack_from('<5I', data, pool + 8)
    if flags & 0x100:
        raise ValueError('Expected Godot UTF-16 string pool')
    strings = []
    for index in range(count):
        at = pool + start + u32(data, pool + header_size + index * 4)
        length = u16(data, at)
        at += 2
        if length & 0x8000:
            length = ((length & 0x7fff) << 16) | u16(data, at)
            at += 2
        strings.append(bytes(data[at:at + length * 2]).decode('utf-16-le'))

    package = None
    providers = []
    for kind, at, _ in chunks:
        if kind != 0x102:
            continue
        tag = strings[u32(data, at + 20)]
        attrs = {}
        attr_start, attr_size, attr_count = struct.unpack_from('<3H', data, at + 24)
        for index in range(attr_count):
            attr = at + 16 + attr_start + index * attr_size
            name = strings[u32(data, attr + 4)]
            raw = u32(data, attr + 8)
            if raw != 0xffffffff:
                attrs[name] = (strings[raw], attr)
        if tag == 'manifest':
            package = attrs['package'][0]
        if tag == 'provider':
            providers.append(attrs)
    if not package:
        raise ValueError('Manifest has no package ID')
    startup = [p for p in providers if p.get('name', ('',))[0] == 'androidx.startup.InitializationProvider']
    if len(startup) != 1:
        raise ValueError('Expected exactly one AndroidX Startup provider')
    wanted = package + '.androidx-startup'
    current, attr = startup[0]['authorities']
    if current == wanted:
        return source
    if current != package + '.fileprovider':
        raise ValueError('Unexpected authority; refusing an unrelated manifest rewrite')
    if data[attr + 15] != 3:
        raise ValueError('Provider authority is not a string')
    new_index = len(strings)
    struct.pack_into('<I', data, attr + 8, new_index)
    struct.pack_into('<I', data, attr + 16, new_index)
    strings.append(wanted)
    offsets, encoded = [], bytearray()
    for text in strings:
        offsets.append(len(encoded))
        raw = text.encode('utf-16-le')
        length = len(raw) // 2
        if length >= 0x8000:
            encoded += struct.pack('<HH', 0x8000 | (length >> 16), length & 0xffff)
        else:
            encoded += struct.pack('<H', length)
        encoded += raw + b'\0\0'
    encoded += b'\0' * (-len(encoded) % 4)
    style_offsets = data[pool + header_size + count * 4:pool + header_size + (count + style_count) * 4]
    style_data = data[pool + style_start:pool + pool_size] if style_start else b''
    new_start = header_size + (len(strings) + style_count) * 4
    new_styles = new_start + len(encoded) if style_data else 0
    new_pool = bytearray(data[pool:pool + header_size])
    new_pool += struct.pack('<' + 'I' * len(offsets), *offsets) + style_offsets + encoded + style_data
    struct.pack_into('<I', new_pool, 4, len(new_pool))
    struct.pack_into('<5I', new_pool, 8, len(strings), style_count, flags & ~1, new_start, new_styles)
    result = data[:pool] + new_pool + data[pool + pool_size:]
    struct.pack_into('<I', result, 4, len(result))
    # Idempotence also verifies that the rebuilt XML still resolves its attributes.
    if fix_manifest(bytes(result)) != result:
        raise ValueError('Manifest repair did not stabilize')
    return bytes(result)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    if args.destination.exists() or args.source.resolve() == args.destination.resolve():
        raise ValueError('Use a fresh unsigned output path')
    with zipfile.ZipFile(args.source) as source, zipfile.ZipFile(args.destination, 'x') as target:
        for entry in source.infolist():
            name = entry.filename.upper()
            if name.startswith('META-INF/') and (name == 'META-INF/MANIFEST.MF' or name.endswith(('.SF', '.RSA', '.DSA', '.EC'))):
                continue
            payload = source.read(entry)
            if entry.filename == 'AndroidManifest.xml':
                payload = fix_manifest(payload)
            target.writestr(entry, payload)
    print('AndroidX Startup authority repaired; unsigned APK ready for alignment and signing.')


if __name__ == '__main__':
    main()
