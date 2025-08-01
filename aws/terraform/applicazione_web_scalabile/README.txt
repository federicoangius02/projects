# Applicazione Web Scalabile su AWS

## Introduzione

Questo progetto dimostrativo mostra come costruire un'infrastruttura scalabile e sicura su AWS per un'applicazione web.  
L'obiettivo è realizzare una soluzione cloud-native che sfrutti servizi gestiti come ECS, S3, DynamoDB, Load Balancer, Auto Scaling e VPC, con particolare attenzione a sicurezza, automazione e best practice DevOps tramite Terraform.

---

## Moduli e Componenti

### 1. **Backend Node.js (ECS)**
- **Funzione:** Espone API REST per upload file, lista file e health check.
- **Deploy:** Container Docker su ECS EC2.
- **Configurazione:** Variabili d’ambiente per S3, DynamoDB, regione AWS.
- **Logging:** Invia log su CloudWatch tramite Winston.
- **Health check:** Endpoint `/health` per monitoraggio.
- **Nota:** Il codice backend è stato adattato da risorse open source.

### 2. **Docker**
- **Immagine:** Node.js 20 Alpine, solo dipendenze di produzione.
- **Porta esposta:** 3000.
- **Build & Push:** L’immagine viene caricata su ECR e usata da ECS.

### 3. **VPC e Networking** (`networking.tf`)
- **VPC:** Rete isolata con subnet pubbliche e private.
- **Subnet:** Pubbliche per ALB, private per ECS.
- **Internet Gateway:** Accesso pubblico solo per ALB.
- **Route Table:** Gestione routing tra subnet e servizi AWS.
- **VPC Endpoints:** Accesso privato a S3, DynamoDB, ECR, SSM senza uscire da AWS.

### 4. **Security Group**
- **ALB:** Accetta solo traffico HTTP/HTTPS pubblico.
- **ECS:** Accetta solo traffico dall’ALB sulla porta 3000.
- **Regole di uscita:** Consentono solo il traffico necessario.

### 5. **Load Balancer & Target Group**
- **ALB:** Distribuisce il traffico verso i container ECS.
- **Target Group:** Monitora lo stato dei container tramite health check su `/health`.

### 6. **Auto Scaling** (`networking.tf`)
- **Auto Scaling Group:** Scala automaticamente le istanze ECS in base al carico.
- **Attach:** Collega le istanze ECS al target group dell’ALB.

### 7. **ECS Cluster & Service** (`backend.tf`)
- **Cluster:** Gestisce i container su EC2.
- **Service:** Mantiene il numero desiderato di task attivi, gestisce il bilanciamento tramite ALB.
- **Task Definition:** Specifica immagine, risorse, variabili d’ambiente e logging.

### 8. **IAM & Sicurezza** (`backend.tf`)
- **Ruoli ECS:** Permessi minimi per accedere a S3, DynamoDB, ECR.
- **Policy personalizzata:** Solo le azioni strettamente necessarie sono consentite.

### 9. **S3 Storage** (`storage.tf`)
- **Backend Bucket:** Privato, cifrato, versionato. Usato per file utente.
- **Frontend Bucket:** Pubblico solo per la lettura, configurato come static website.
- **Access Block:** Protegge il bucket backend da accessi pubblici.

### 10. **DynamoDB** (`storage.tf`)
- **Tabella:** Memorizza i metadati dei file caricati.
- **Sicurezza:** Cifratura abilitata, billing PAY_PER_REQUEST.

### 11. **CloudFront (da implementare)**
- **Funzione:** Distribuzione CDN per il bucket S3 del frontend.
- **Vantaggi:** Migliora performance e sicurezza dei contenuti statici.

### 12. **ElastiCache (bonus, da implementare)**
- **Funzione:** Cache Redis/Memcached per ottimizzare le performance del backend.

---

## Sicurezza

- **Bucket S3 backend privato**: Nessun accesso pubblico.
- **Bucket S3 frontend pubblico solo per la lettura**.
- **ECS accessibile solo tramite ALB**.
- **IAM con permessi minimi**.
- **VPC Endpoints per traffico privato verso servizi AWS**.
- **Nessuna istanza ECS con IP pubblico**.

---

## Deployment

1. **Build & Push Docker**:  
   Costruisci l’immagine e pubblicala su ECR.
2. **Terraform Apply**:  
   Esegui `terraform apply` per creare/aggiornare l’infrastruttura.
3. **Verifica**:  
   - Testa le API (`/upload`, `/files`, `/health`).
   - Controlla i log su CloudWatch.
   - Verifica la sicurezza dei bucket S3 e delle regole di rete.

---

## Cosa manca da implementare

- **CloudFront** per il bucket S3 del frontend.
- **ElastiCache** per la cache (bonus).
- **Documentazione dettagliata** su deploy, test e gestione.
- **Monitoraggio avanzato** (allarmi CloudWatch, metriche custom).

---

## Note finali

Il backend Node.js utilizzato è solo un esempio, non è stato sviluppato interamente da me, ma serve esclusivamente a dimostrare l’integrazione con i servizi AWS;
il fulcro del lavoro è infatti l’infrastruttura, la sicurezza e l’automazione.