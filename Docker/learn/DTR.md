# DTR
Docker Trusted Registry (DTR) is a containerized application that runs on a Docker Universal Control Plane cluster.

![DTR](https://docs.docker.com/datacenter/dtr/2.2/guides/images/architecture-1.svg)

# DTR内部组件
When you install DTR on a node, the following containers are started:

Name | Description
---- | ----
dtr-api-&lt;replica_id> | Executes the DTR business logic. It serves the DTR web application, and API
dtr-garant-&lt;replica_id>	|Manages DTR authentication
dtr-jobrunner-&lt;replica_id> | Runs cleanup jobs in the background
dtr-nautilusstore-&lt;replica_id> | Stores security scanning data
dtr-nginx-&lt;replica_id>|	Receives http and https requests and proxies them to other DTR components. By default it listens to ports 80 and 443 of the host
dtr-notary-server-&lt;replica_id>	|Receives, validates, and serves content trust metadata, and is consulted when pushing or pulling to DTR with content trust enabled
dtr-notary-signer-&lt;replica_id>	|Performs server-side timestamp and snapshot signing for content trust metadata
dtr-registry-&lt;replica_id>	|Implements the functionality for pulling and pushing Docker images. It also handles how images are stored
dtr-rethinkdb-&lt;replica_id>	|A database for persisting repository metadata

## Install UCP for production
UCP is a containerized application that requires the **commercially supported Docker Engine** to run.

卒。。。。。
