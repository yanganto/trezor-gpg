#!/usr/bin/env -S python -u
# `-u` is for Windows, that stdin and stdout in binary, rather than text
# TODO: rewrite this poc with Rust

import json
import sys
import os
import struct
import subprocess


def get_message():
    raw_length = sys.stdin.buffer.read(4)

    if not raw_length:
        sys.exit(0)
    message_length = struct.unpack('=I', raw_length)[0]
    message = sys.stdin.buffer.read(message_length).decode("utf-8")
    return json.loads(message)


def encode_message(message_content):
    encoded_content = json.dumps(message_content).encode("utf-8")
    encoded_length = struct.pack('=I', len(encoded_content))
    return dict(length=encoded_length,
                content=struct.pack(str(len(encoded_content))+"s",
                                    encoded_content))


def send_message(encoded_message):
    sys.stdout.buffer.write(encoded_message['length'])
    sys.stdout.buffer.write(encoded_message['content'])
    sys.stdout.buffer.flush()


def decrypt_message(msg):
    try:
        env = os.environ.copy()
        env['GNUPGHOME'] = '~/.gnupg/trezor'
        proc = subprocess.Popen(["gpg2", "--decrypt"],
                                shell=True,
                                env=env,
                                stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE)
        proc.stdin.write(msg.encode("utf-8"))
        out, _ = proc.communicate(timeout=60)
        return encode_message(out.decode("utf-8"))
    except Exception as e:
        return encode_message(str(e))


while True:
    message = get_message()
    if message.startswith("sign:"):
        send_message(encode_message("signature"))
    elif message.startswith("decrypt:"):
        send_message(decrypt_message(message[8:]))
