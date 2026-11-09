# Práctica 8 – Automatización de servidores con Ansible y Docker

**Electiva 2 – ITLA**

Este proyecto utiliza **Docker Compose** para levantar cinco contenedores basados en Ubuntu 24.04 con SSH. Son contenedores aislados, no máquinas virtuales completas. Desde la computadora anfitriona, **Ansible** configura los cinco servidores mediante un solo playbook.

## Requisitos

- Docker y Docker Compose (`docker compose`).
- Ansible y `sshpass` instalados en Linux o WSL.
- Acceso a Internet para descargar la imagen Ubuntu y los paquetes APT.

En **Fedora**:

```bash
sudo dnf install -y ansible sshpass
```

En **Ubuntu / WSL**:

```bash
sudo apt update
sudo apt install -y ansible sshpass
```

Si usas Windows, instala WSL (`wsl --install`), además de Docker Desktop con integración WSL, y ejecuta los comandos de Ansible desde la terminal de Ubuntu.

## Archivos del proyecto

| Archivo | Propósito |
| --- | --- |
| `Dockerfile` | Crea una imagen Ubuntu con SSH, Python 3 y dependencias APT, usuario `ansible` y sudo sin contraseña. |
| `docker-compose.yml` | Define los cinco servidores Ubuntu y sus puertos SSH. |
| `inventario.ini` | Registra el nombre, dirección, puerto, usuario y contraseña de cada servidor. |
| `ansible.cfg` | Configura el inventario y desactiva la comprobación de la clave SSH para el laboratorio. |
| `playbook.yml` | Automatiza todas las tareas solicitadas. |

## 1. Levantar los cinco servidores

Primero comprueba que Docker y Compose estén instalados:

```bash
docker --version
docker compose version
```

Desde la carpeta de este repositorio:

```bash
docker compose up -d --build
docker compose ps
```

Los cinco servidores escuchan en **127.0.0.1** con diferentes puertos SSH:

| Servidor | IP desde Ansible | Puerto SSH |
| --- | --- | --- |
| `ubuntu1` | `127.0.0.1` | `2221` |
| `ubuntu2` | `127.0.0.1` | `2222` |
| `ubuntu3` | `127.0.0.1` | `2223` |
| `ubuntu4` | `127.0.0.1` | `2224` |
| `ubuntu5` | `127.0.0.1` | `2225` |

Cada contenedor genera su propia clave SSH al iniciarse. Cada puerto se redirige al puerto 22 de **un contenedor diferente**. De este modo el inventario funciona sin usar direcciones IP internas de Docker, que pueden variar.

## 2. Verificar la conexión de Ansible

```bash
ansible servidores -m ansible.builtin.ping
```

Cada servidor debe responder con `"ping": "pong"` y `SUCCESS`.

## 3. Ejecutar el playbook

```bash
ansible-playbook --syntax-check playbook.yml
ansible-playbook playbook.yml
```

El playbook realiza estas operaciones **en los cinco servidores**:

1. Actualiza la caché de paquetes de APT.
2. Crea el usuario `itla` con su directorio personal.
3. Crea `/home/itla/app`.
4. Crea `/home/itla/app/hola.txt` con un saludo que identifica al servidor.
5. Instala los paquetes `cowsay` y `htop`.

El resultado final esperado es un `PLAY RECAP` con `failed=0` y `unreachable=0` para los cinco servidores.

## 4. Comprobar los resultados

Comprobar desde Ansible que el usuario existe:

```bash
ansible servidores -b -m ansible.builtin.command -a 'id itla'
```

Comprobar que la carpeta, el archivo y los paquetes existen en un contenedor:

```bash
docker compose exec ubuntu1 cat /home/itla/app/hola.txt
docker compose exec ubuntu1 ls -l /home/itla/app
docker compose exec ubuntu1 dpkg-query -W cowsay htop
docker compose exec ubuntu1 /usr/games/cowsay "Hola ITLA"
```

Repite la comprobación con `ubuntu2`, `ubuntu3`, `ubuntu4` y `ubuntu5`, o usa Ansible para consultar todos a la vez:

```bash
ansible servidores -b -m ansible.builtin.command -a 'cat /home/itla/app/hola.txt'
ansible servidores -b -m ansible.builtin.command -a 'dpkg-query -W cowsay htop'
```

Al ejecutar `ansible-playbook playbook.yml` otra vez, las tareas que no necesitan cambios deben aparecer con `ok` en lugar de `changed` (idempotencia).

## 5. Apagar el laboratorio

```bash
docker compose down
```

Para eliminar también los contenedores y volver a crearlos desde cero, utiliza `docker compose down` seguido de `docker compose up -d --build`.

## Evidencias sugeridas para la entrega

Toma capturas de `docker compose ps`, los cinco resultados `SUCCESS` del comando `ansible ... ping`, el resumen `PLAY RECAP` del playbook y una comprobación del usuario, archivo y aplicaciones instaladas. **No se incluyen capturas ni resultados inventados**: debes obtenerlos al ejecutar los comandos en tu computadora.

> **Seguridad:** La contraseña `ansible` y `host_key_checking = False` se usan únicamente porque son requisitos de este laboratorio local. Los puertos SSH están restringidos a `127.0.0.1`. No reutilices esta configuración en servidores reales ni en redes públicas.
