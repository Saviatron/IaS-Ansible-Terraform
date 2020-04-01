# IaS-Ansible-Terraform

En este repositorio se recoge la tarea propuesta sobre "Infraestructura como Código".

Esta tarea se desarrollará con Google Cloud Platform.

Para realizar esta tarea podemos utilizar Cloud Shell o crear una instancia de Compute Engine.
En mi caso, he creado una instancia de Compute Engine en la que instalaré en primer lugar Terraform y Ansible:

- Instalar Ansible:

```
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt install ansible
```


- Instalar Terraform:
```
wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
sudo apt-get install unzip
unzip terraform_0.12.24_linux_amd64.zip
sudo mv terraform /usr/local/bin
terraform --version
```

# 1. Crear Infraestructura mediante Terraform.

En primer lugar, deberemos obtener el fichero con las credenciales de GCP y generar las claves ssh.

Luego crearemos los siguientes ficheros de conficuración:

### proveedor.tf
````
provider "google" {
  credentials = file("~/credentials.json")
  project     = "stellar-psyche-268616"
  region      = "us-central1"
  zone        = "us-central1-a"
}
````

### ip.tf
````
resource "google_compute_address" "ip-lb" {
  name = "ip-lb"
}
resource "google_compute_address" "ip-ws1" {
  name = "ip-ws1"
}
resource "google_compute_address" "ip-ws2" {
  name = "ip-ws2"
}
resource "google_compute_address" "ip-int-lb" {
  name         = "ip-int-lb"
  subnetwork   = "default"
  address_type = "INTERNAL"
  address      = "10.128.0.11"
  region       = "us-central1"
}
resource "google_compute_address" "ip-int-ws1" {
  name         = "ip-int-ws1"
  subnetwork   = "default"
  address_type = "INTERNAL"
  address      = "10.128.0.12"
  region       = "us-central1"
}
resource "google_compute_address" "ip-int-ws2" {
  name         = "ip-int-ws2"
  subnetwork   = "default"
  address_type = "INTERNAL"
  address      = "10.128.0.13"
  region       = "us-central1"
}
````

### vm.tf
````
resource "google_compute_instance" "lb" {
  name         = "terraform-lb"
  machine_type = "n1-standard-1"
  tags         = ["terraform", "http-server"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1910-eoan-v20200331"
    }
  }
  network_interface {
    network    = "default"
    network_ip = google_compute_address.ip-int-lb.address
    access_config {
      nat_ip = google_compute_address.ip-lb.address
    }
  }
  metadata = {
    ssh-keys = "javimm97:${file("~/.ssh/sshkey.pub")}"
  }
}

resource "google_compute_instance" "ws1" {
  name         = "terraform-ws1"
  machine_type = "n1-standard-1"
  tags         = ["terraform", "http-server"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1910-eoan-v20200331"
    }
  }
  network_interface {
    network    = "default"
    network_ip = google_compute_address.ip-int-ws1.address
    access_config {
      nat_ip = google_compute_address.ip-ws1.address
    }
  }
  metadata = {
    ssh-keys = "javimm97:${file("~/.ssh/sshkey.pub")}"
  }
}

resource "google_compute_instance" "ws2" {
  name         = "terraform-ws2"
  machine_type = "n1-standard-1"
  tags         = ["terraform", "http-server"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1910-eoan-v20200331"
    }
  }
  network_interface {
    network    = "default"
    network_ip = google_compute_address.ip-int-ws2.address
    access_config {
      nat_ip = google_compute_address.ip-ws2.address
    }
  }
  metadata = {
    ssh-keys = "javimm97:${file("~/.ssh/sshkey.pub")}"
  }
}
````

### output.tf
````
output "ip-lb" {
  value = google_compute_address.ip-lb.address
}

output "ip-int-lb" {
  value = google_compute_address.ip-int-lb.address
}

output "ip-ws1" {
  value = google_compute_address.ip-ws1.address
}

output "ip-int-ws1" {
  value = google_compute_address.ip-int-ws1.address
}

output "ip-ws2" {
  value = google_compute_address.ip-ws2.address
}

output "ip-int-ws2" {
  value = google_compute_address.ip-int-ws2.address
}
````

### Para crear la Infraestructura descrita con Terraform:
````
terraform init
terraform plan
terraform apply
````


Obtendremos como salida las direcciones IPs, que serán necesarias para trabajar con Ansible.


# 2. Configurar Infraestructura mediante Ansible.

En primer lugar, crearemos los ficheros de configuración de Ansible:

### ansible.cfg
````
# ansible.cfg

[defaults]
inventory = ./hosts-dev
remote_user = javimm97
private_key_file = ~/.ssh/sshkey
host_key_checking = False
retry_files_enabled = False

# Para usuarios de Windows
[ssh_connection]
ssh_args = -o ControlMaster=no
````

### hosts-dev
````
# Añadiremos aquí las IPs del "output" de Terraform.

[webservers]
webapp1 ansible_host=x.x.x.x
webapp2 ansible_host=x.x.x.x

[loadbalancer]
weblb ansible_host=x.x.x.x

[local]
control ansible_connection=local
````

A continuación, crearemos los PlayBooks de Ansible:

### apt-update.yml
````
  - hosts: webservers:loadbalancer
    become: true
    tasks:
      - name: Updating apt packages
        apt: name=* state=latest
````

### install-services.yml
````
  - hosts: loadbalancer
    become: true
    tasks:
      - name: Installing apache
        apt: name=apache2 update_cache=yes state=present
      - name: Ensure apache starts
        service: name=apache2 state=started enabled=yes

  - hosts: webservers
    become: true
    tasks:
      - name: Installing services
        apt:
          name: 
            - apache2
            - php
            - mysql-server
          update_cache: yes
          state: present
      - name: Ensure apache starts
        service: name=apache2 state=started enabled=yes
      - name: Ensure mysql starts
        service: name=mysql state=started enabled=yes

  - hosts: local
    become: true
    tasks:
      - name: Installing services
        apt: name=mysql-client update_cache=yes state=present
      - name: Ensure mysql starts
        service: name=mysql state=started enabled=yes
````

### setup-app.yml
````
  - hosts: webservers
    become: true
    tasks:
      - name: Upload application file
        copy:
          src: app/index.php
          dest: /var/www/html
          mode: 0755

      - name: Configure php.ini file
        lineinfile:
          path: /etc/php/7.3/apache2/php.ini
          regexp: ^short_open_tag
          line: 'short_open_tag=On'
        notify: restart apache

    handlers:
      - name: restart apache
        service: name=apache2 state=restarted
````

### setup-lb.yml
````
  - hosts: loadbalancer
    become: true
    tasks:
      - name: enabled mod 1
        apache2_module: name=proxy state=present
      - name: enabled mod 2
        apache2_module: name=proxy_http state=present
      - name: enabled mod 3
        apache2_module: name=proxy_balancer state=present
      - name: enabled mod 4
        apache2_module: name=lbmethod_byrequests state=present

      - name: Creating template
        template:
          src: config/lb-config.j2
          dest: /etc/apache2/mods-enabled/proxy_balancer.conf
        notify: restart apache
    
    handlers:
      - name: restart apache
        service: name=apache2 state=restarted enabled=yes
````

### check-status.yml
````
  - hosts: webservers:loadbalancer
    become: true
    tasks:
      - name: Check status of apache
        #command: service httpd status
        #service: name=httpd
        shell: 
          cmd: service apache2 status
          warn: False
````

### all-playbooks.yml
````
  - import_playbook: apt-update.yml
  - import_playbook: install-services.yml
  - import_playbook: setup-app.yml
  - import_playbook: setup-lb.yml
  - import_playbook: check-status.yml
````

### Para configurar la Infraestructura descrita con Ansible:
````
ansible-playbook playbooks/all-playbooks.yml
````


Finalmente, para ver el Balanceador de cargas en acción, refrescaremos la página varias veces y veremos como alterna entre el Servidor web 1 y el Servidor web 2
http://x.x.x.x/index.php
