# DNS en el runner (Flink)

En algunos runners el endpoint de Flink no resuelve con el DNS interno. `configure-dns.sh` guarda `/etc/resolv.conf` en `/tmp/resolv.conf.backup` y pone `8.8.8.8` / `1.1.1.1`. `restore-dns.sh` lo deja como estaba.

El workflow llama configure antes de Terraform y restore al final (también si el job falla). Se necesita sudo.

En local:

```bash
sudo ./configure-dns.sh
terraform apply
sudo ./restore-dns.sh
```

Si restore se queja de que no hay backup, no ejecutaste configure. Vault y el resto de servicios del runner no deberían quedar apuntando a 8.8.8.8: por eso el restore es obligatorio.
