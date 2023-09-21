# что внутри
# playbook для ansible
# задача - обновить сертификат внутри докер контейнеров, на каждом хосте крутится несколько контейнеров

настроить копирование сертификатов средствами Ansible на сервера 

dev1 172.30.58.140
dev2 172.30.58.141
dev3 172.30.58.143
 

master host (с которого будет Push ) DEV11 - 172.30.58.123

# содержимое плейбука
nano /etc/ansible/playbooks/update_cert_on_dockers.yaml

```
- hosts: dev_mlservice
  tasks: 
    - name: Main block
      block: 
        - name: Install 7z
          apt: name=p7zip-full update_cache=yes
          tags: 
            - install

        - name: Create directory for cert
          file: 
            path: /opt/certupdate/tempcert
            state: directory
          tags: 
            - mkdir

        - name: Download cert
          get_url: 
            url: https://site.ru/cert.dll
            dest: /opt/certupdate/cert.7z
          tags: 
            - wget

        - name: Unzip
          shell: /usr/bin/7z -y x -p{{ pass_for_zip }} /opt/certupdate/cert.7z -o/opt/certupdate/tempcert/
          tags: 
            - unzip

        - name: Copy script
          copy: 
            src: /etc/ansible/scripts/restart-docker.sh
            dest: /tmp/restart-docker.sh
            remote_src: no
            mode: 0755
            owner: root
            group: root
          tags: 
            - copy_script

        - name: Run script = restart docker
          shell: /bin/bash /tmp/restart-docker.sh
          tags: 
            - run_script


      become: true
      become_user: root
```

# содержимое скрипта
nano /etc/ansible/scripts/restart-docker.sh
```
#get all names of the running containers
b=(`docker ps | awk '{print $ 13}' | tail -n +2`)
#copy certificates into containers
for name in ${b[@]}; do docker cp /opt/certupdate/tempcert/cert.pfx $name:/app ; done
#restart all containers
for name in ${b[@]}; do docker restart $name ; done
```
# содержимое списка хостов и списка переменных
nano /etc/ansible/hosts
```
[dev_mlservice]
172.30.58.140
172.30.58.141
172.30.58.143

[dev_mlservice:vars]
ansible_user=alexey
pass_for_zip=123
```


# запуск
ansible-playbook /etc/ansible/playbooks/update_cert_on_dockers.yaml
