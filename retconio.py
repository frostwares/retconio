import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind(("localhost", 60_000))
sock.listen(2)


def connect():
    soc, addr = sock.accept()
    soc.settimeout(1)
    return soc


def read_socket(soc):
    full_msg = ''
    try:
        while True:
            msg = soc.recv(8)
            full_msg += msg.decode()
            if msg.decode().find("\n") != -1:
                break
        return full_msg
    except socket.timeout:
        return "timeout"


def write_socket(soc, msg):
    soc.send(msg.encode())
    return read_socket(soc)  # check for a response


if __name__ == "__main__":
    print("main: RetConIO Server")
