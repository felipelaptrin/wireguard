import sqlite3

DB_NAME = "wireguard.db"
INITIAL_PRIVATE_IP = "10.0.0.10"


def create_db():
    try:
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                private_ip TEXT
            );
        """)
        conn.close()
    except Exception as e:
        print(e)


def get_new_private_ip():
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("SELECT max(id) from users")
    id = cursor.fetchone()[0]
    if id:
        assert int(id) < 200, "Max number of connections in the VPN."
        ip_blocks = INITIAL_PRIVATE_IP.split(".")
        last_block = int(ip_blocks[-1]) + int(id)
        full_block = ip_blocks[:4] + [str(last_block)]
        ip = ".".join(full_block)
        return ip
    conn.close()
    return INITIAL_PRIVATE_IP


def create_user(new_private_ip: str):
    print(new_private_ip)
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute(
        """INSERT INTO users(private_ip) VALUES (?)""",
        (new_private_ip,),
    )
    conn.commit()
    conn.close()

    return new_private_ip
