auto.create.topics.enable
-------------------------

Enable auto creation of topic on the server.

Type: boolean
Default: true
Valid Values:
Importance: high
Update Mode: read-only


auto.leader.rebalance.enable
----------------------------

Enables auto leader balancing. A background thread checks the distribution of
partition leaders at regular intervals, configurable by
leader.imbalance.check.interval.seconds. If the leader imbalance exceeds
leader.imbalance.per.broker.percentage, leader rebalance to the preferred
leader for partitions is triggered.

Type: boolean
Default: true
Valid Values:
Importance: high
Update Mode: read-only


background.threads
------------------

The number of threads to use for various background processing tasks

Type: int
Default: 10
Valid Values: [1,...]
Importance: high
Update Mode: cluster-wide


broker.id
---------

The broker id for this server. If unset, a unique broker id will be
generated.To avoid conflicts between ZooKeeper generated broker id's and user
configured broker id's, generated broker ids start from reserved.broker.max.id + 1.

Type: int
Default: -1
Valid Values:
Importance: high
Update Mode: read-only


compression.type
----------------

Specify the final compression type for a given topic. This configuration
accepts the standard compression codecs ('gzip', 'snappy', 'lz4', 'zstd'). It
additionally accepts 'uncompressed' which is equivalent to no compression; and
'producer' which means retain the original compression codec set by the
producer.

Type: string
Default: producer
Valid Values: [uncompressed, zstd, lz4, snappy, gzip, producer]
Importance: high
Update Mode: cluster-wide


control.plane.listener.name
---------------------------

Name of listener used for communication between controller and brokers. A
broker will use the control.plane.listener.name to locate the endpoint in
listeners list, to listen for connections from the controller. For example, if
a broker's config is:

listeners = INTERNAL://192.1.1.8:9092, EXTERNAL://10.1.1.5:9093, CONTROLLER://192.1.1.8:9094

listener.security.protocol.map = INTERNAL:PLAINTEXT, EXTERNAL:SSL, CONTROLLER:SSL

control.plane.listener.name = CONTROLLER

On startup, the broker will start listening on 192.1.1.8:9094 with security
protocol SSL.

On the controller side, when it discovers a broker's published endpoints
through ZooKeeper, it will use the control.plane.listener.name to find the
endpoint, which it will use to establish connection to the broker.

For example, if the broker's published endpoints on ZooKeeper are:

endpoints:
INTERNAL://broker1.example.com:9092,EXTERNAL://broker1.example.com:9093,CONTROLLER://broker1.example.com:9094


and the controller's config is:

listener.security.protocol.map =
INTERNAL:PLAINTEXT, EXTERNAL:SSL, CONTROLLER:SSLcontrol.plane.listener.name = CONTROLLER

then the controller will use broker1.example.com:9094 with security protocol SSL to connect to the broker.

If not explicitly configured, the default value will be null and there will be
no dedicated endpoints for controller connections.

If explicitly configured, the value cannot be the same as the value of
inter.broker.listener.name.

Type: string
Default: null
Valid Values:
Importance: high
Update Mode: read-only


controller.listener.names
-------------------------

A comma-separated list of the names of the listeners used by the controller.
This is required if running in KRaft mode. When communicating with the
controller quorum, the broker will always use the first listener in this list.

Note: The ZooKeeper-based controller should not set this configuration.

Type: string
Default: null
Valid Values:
Importance: high
Update Mode: read-only


controller.quorum.election.backoff.max.ms
-----------------------------------------

Maximum time in milliseconds before starting new elections. This is used in the
binary exponential backoff mechanism that helps prevent gridlocked elections

Type: int
Default: 1000 (1 second)
Valid Values:
Importance: high
Update Mode: read-only


controller.quorum.election.timeout.ms
-------------------------------------

Maximum time in milliseconds to wait without being able to fetch from the
leader before triggering a new election

Type: int
Default: 1000 (1 second)
Valid Values:
Importance: high
Update Mode: read-only


controller.quorum.fetch.timeout.ms
----------------------------------

Maximum time without a successful fetch from the current leader before becoming
a candidate and triggering an election for voters; Maximum time a leader can go
without receiving valid fetch or fetchSnapshot request from a majority of the
quorum before resigning.

Type: int
Default: 2000 (2 seconds)
Valid Values:
Importance: high
Update Mode: read-only


controller.quorum.voters
------------------------

Map of id/endpoint information for the set of voters in a comma-separated list
of {id}@{host}:{port} entries. For example:
1@localhost:9092,2@localhost:9093,3@localhost:9094

Type: list
Default:
Valid Values: non-empty list
Importance: high
Update Mode: read-only


delete.topic.enable
-------------------

Enables delete topic. Delete topic through the admin tool will have no effect
if this config is turned off

Type: boolean
Default: true
Valid Values:
Importance: high
Update Mode: read-only


early.start.listeners
---------------------

A comma-separated list of listener names which may be started before the
authorizer has finished initialization. This is useful when the authorizer is
dependent on the cluster itself for bootstrapping, as is the case for the
StandardAuthorizer (which stores ACLs in the metadata log.) By default, all
listeners included in controller.listener.names will also be early start
listeners. A listener should not appear in this list if it accepts external
traffic.

Type: string
Default: null
Valid Values:
Importance: high
Update Mode: read-only


eligible.leader.replicas.enable
-------------------------------

Enable the Eligible leader replicas

Type: boolean
Default: false
Valid Values:
Importance: high
Update Mode: read-only


leader.imbalance.check.interval.seconds
---------------------------------------

The frequency with which the partition rebalance check is triggered by the
controller

Type: long
Default: 300
Valid Values: [1,...]
Importance: high
Update Mode: read-only


leader.imbalance.per.broker.percentage
--------------------------------------

The ratio of leader imbalance allowed per broker. The controller would trigger
a leader balance if it goes above this value per broker. The value is specified
in percentage.

Type: int
Default: 10
Valid Values:
Importance: high
Update Mode: read-only


listeners
---------

Listener List - Comma-separated list of URIs we will listen on and the listener
names. If the listener name is not a security protocol,
listener.security.protocol.map must also be set.

 Listener names and port numbers must be unique unless one listener is an
 IPv4 address and the other listener is an IPv6 address (for the same
 port). Specify hostname as 0.0.0.0 to bind to all interfaces. Leave
 hostname empty to bind to default interface.

 Examples of legal listener lists:

 PLAINTEXT://myhost:9092,SSL://:9091, CLIENT://0.0.0.0:9092,REPLICATION://localhost:9093,
 PLAINTEXT://127.0.0.1:9092,SSL://[:1]:9092

Type: string
Default: PLAINTEXT://:9092
Valid Values:
Importance: high
Update Mode: per-broker


log.dir
-------

The directory in which the log data is kept (supplemental for log.dirs
property)

Type: string
Default: /tmp/kafka-logs
Valid Values:
Importance: high
Update Mode: read-only


log.dirs
--------

A comma-separated list of the directories where the log data is stored. If not
set, the value in log.dir is used.

Type: string
Default: null
Valid Values:
Importance: high
Update Mode: read-only


log.flush.interval.messages
---------------------------

The number of messages accumulated on a log partition before messages are
flushed to disk.

Type: long
Default: 9223372036854775807
Valid Values: [1,...]
Importance: high
Update Mode: cluster-wide


log.flush.interval.ms
---------------------

The maximum time in ms that a message in any topic is kept in memory before
flushed to disk. If not set, the value in log.flush.scheduler.interval.ms is
used

Type: long
Default: null
Valid Values:
Importance: high
Update Mode: cluster-wide


log.flush.offset.checkpoint.interval.ms
---------------------------------------

The frequency with which we update the persistent record of the last flush
which acts as the log recovery point.

Type: int
Default: 60000 (1 minute)
Valid Values: [0,...]
Importance: high
Update Mode: read-only


log.flush.scheduler.interval.ms
-------------------------------

The frequency in ms that the log flusher checks whether any log needs to be
flushed to disk

Type: long
Default: 9223372036854775807
Valid Values:
Importance: high
Update Mode: read-only


log.flush.start.offset.checkpoint.interval.ms
---------------------------------------------

The frequency with which we update the persistent record of log start offset

Type: int
Default: 60000 (1 minute)
Valid Values: [0,...]
Importance: high
Update Mode: read-only


log.retention.bytes
-------------------

The maximum size of the log before deleting it

Type: long
Default: -1
Valid Values:
Importance: high
Update Mode: cluster-wide


log.retention.hours
-------------------

The number of hours to keep a log file before deleting it (in hours), tertiary
to log.retention.ms property

Type: int
Default: 168
Valid Values:
Importance: high
Update Mode: read-only


log.retention.minutes
---------------------

The number of minutes to keep a log file before deleting it (in minutes),
secondary to log.retention.ms property. If not set, the value in
log.retention.hours is used

Type: int
Default: null
Valid Values:
Importance: high
Update Mode: read-only


log.retention.ms
----------------

The number of milliseconds to keep a log file before deleting it (in
milliseconds), If not set, the value in log.retention.minutes is used. If set
to -1, no time limit is applied.

Type: long
Default: null
Valid Values:
Importance: high
Update Mode: cluster-wide


log.roll.hours
--------------

The maximum time before a new log segment is rolled out (in hours), secondary
to log.roll.ms property

Type: int
Default: 168
Valid Values: [1,...]
Importance: high
Update Mode: read-only


log.roll.jitter.hours
---------------------

The maximum jitter to subtract from logRollTimeMillis (in hours), secondary to
log.roll.jitter.ms property

Type: int
Default: 0
Valid Values: [0,...]
Importance: high
Update Mode: read-only


log.roll.jitter.ms
------------------

The maximum jitter to subtract from logRollTimeMillis (in milliseconds). If not
set, the value in log.roll.jitter.hours is used

Type: long
Default: null
Valid Values:
Importance: high
Update Mode: cluster-wide


log.roll.ms
-----------

The maximum time before a new log segment is rolled out (in milliseconds). If
not set, the value in log.roll.hours is used

Type: long
Default: null
Valid Values:
Importance: high
Update Mode: cluster-wide


log.segment.bytes
-----------------

The maximum size of a single log file

Type: int
Default: 1073741824 (1 gibibyte)
Valid Values: [14,...]
Importance: high
Update Mode: cluster-wide


log.segment.delete.delay.ms
---------------------------

The amount of time to wait before deleting a file from the filesystem. If the
value is 0 and there is no file to delete, the system will wait 1 millisecond.
Low value will cause busy waiting

Type: long
Default: 60000 (1 minute)
Valid Values: [0,...]
Importance: high
Update Mode: cluster-wide


message.max.bytes
-----------------

The largest record batch size allowed by Kafka (after compression if
compression is enabled). If this is increased and there are consumers older
than 0.10.2, the consumers' fetch size must also be increased so that they can
fetch record batches this large. In the latest message format version, records
are always grouped into batches for efficiency. In previous message format
versions, uncompressed records are not grouped into batches and this limit only
applies to a single record in that case.This can be set per topic with the
topic level max.message.bytes config.

Type: int
Default: 1048588
Valid Values: [0,...]
Importance: high
Update Mode: cluster-wide


metadata.log.dir
----------------

This configuration determines where we put the metadata log for clusters in
KRaft mode. If it is not set, the metadata log is placed in the first log
directory from log.dirs.

Type: string
Default: null
Valid Values:
Importance: high
Update Mode: read-only


metadata.log.max.record.bytes.between.snapshots
-----------------------------------------------

This is the maximum number of bytes in the log between the latest snapshot and
the high-watermark needed before generating a new snapshot. The default value
is 20971520. To generate snapshots based on the time elapsed, see the
metadata.log.max.snapshot.interval.ms configuration. The Kafka node will
generate a snapshot when either the maximum time interval is reached or the
maximum bytes limit is reached.

Type: long
Default: 20971520
Valid Values: [1,...]
Importance: high
Update Mode: read-only


metadata.log.max.snapshot.interval.ms
-------------------------------------

This is the maximum number of milliseconds to wait to generate a snapshot if
there are committed records in the log that are not included in the latest
snapshot. A value of zero disables time based snapshot generation. The default
value is 3600000. To generate snapshots based on the number of metadata bytes,
see the metadata.log.max.record.bytes.between.snapshots configuration. The
Kafka node will generate a snapshot when either the maximum time interval is
reached or the maximum bytes limit is reached.

Type: long
Default: 3600000 (1 hour)
Valid Values: [0,...]
Importance: high
Update Mode: read-only


metadata.log.segment.bytes
--------------------------

The maximum size of a single metadata log file.

Type: int
Default: 1073741824 (1 gibibyte)
Valid Values: [12,...]
Importance: high
Update Mode: read-only


metadata.log.segment.ms
-----------------------

The maximum time before a new metadata log file is rolled out (in
milliseconds).

Type: long
Default: 604800000 (7 days)
Valid Values:
Importance: high
Update Mode: read-only


metadata.max.retention.bytes
----------------------------

The maximum combined size of the metadata log and snapshots before deleting old
snapshots and log files. Since at least one snapshot must exist before any logs
can be deleted, this is a soft limit.

Type: long
Default: 104857600 (100 mebibytes)
Valid Values:
Importance: high
Update Mode: read-only


metadata.max.retention.ms
-------------------------

The number of milliseconds to keep a metadata log file or snapshot before
deleting it. Since at least one snapshot must exist before any logs can be
deleted, this is a soft limit.

Type: long
Default: 604800000 (7 days)
Valid Values:
Importance: high
Update Mode: read-only


min.insync.replicas
-------------------

When a producer sets acks to all (or -1), min.insync.replicas
specifies the minimum number of replicas that must acknowledge a write for the
write to be considered successful. If this minimum cannot be met, then the
producer will raise an exception (either NotEnoughReplicas or
NotEnoughReplicasAfterAppend).

When used together, min.insync.replicas
and acks allow you to enforce greater durability guarantees. A typical scenario
would be to create a topic with a replication factor of 3, set
min.insync.replicas to 2, and produce with acks of all. This will ensure
that the producer raises an exception if a majority of replicas do not receive
a write.

Type: int
Default: 1
Valid Values: [1,...]
Importance: high
Update Mode: cluster-wide


node.id
-------

The node ID associated with the roles this process is playing when
process.roles is non-empty. This is required configuration when running in
KRaft mode.

Type: int
Default: -1
Valid Values:
Importance: high
Update Mode: read-only


num.io.threads
--------------

The number of threads that the server uses for processing requests, which may
include disk I/O

Type: int
Default: 8
Valid Values: [1,...]
Importance: high
Update Mode: cluster-wide


num.network.threads
-------------------

The number of threads that the server uses for receiving requests from the
network and sending responses to the network. Noted: each listener (except for
controller listener) creates its own thread pool.

Type: int
Default: 3
Valid Values: [1,...]
Importance: high
Update Mode: cluster-wide


num.recovery.threads.per.data.dir
---------------------------------

The number of threads per data directory to be used for log recovery at startup
and flushing at shutdown

Type: int
Default: 1
Valid Values: [1,...]
Importance: high
Update Mode: cluster-wide


num.replica.alter.log.dirs.threads
----------------------------------

The number of threads that can move replicas between log directories, which may
include disk I/O

Type: int
Default: null
Valid Values:
Importance: high
Update Mode: read-only


num.replica.fetchers
--------------------

Number of fetcher threads used to replicate records from each source broker.
The total number of fetchers on each broker is bound by num.replica.fetchers
multiplied by the number of brokers in the cluster.Increasing this value can
increase the degree of I/O parallelism in the follower and leader broker at the
cost of higher CPU and memory utilization.

Type: int
Default: 1
Valid Values:
Importance: high
Update Mode: cluster-wide


offset.metadata.max.bytes
-------------------------

The maximum size for a metadata entry associated with an offset commit.

Type: int
Default: 4096 (4 kibibytes)
Valid Values:
Importance: high
Update Mode: read-only


offsets.commit.required.acks
----------------------------

DEPRECATED: The required acks before the commit can be accepted. In general,
the default (-1) should not be overridden.

Type: short
Default: -1
Valid Values:
Importance: high
Update Mode: read-only


offsets.commit.timeout.ms
-------------------------

Offset commit will be delayed until all replicas for the offsets topic receive
the commit or this timeout is reached. This is similar to the producer request
timeout.

Type: int
Default: 5000 (5 seconds)
Valid Values: [1,...]
Importance: high
Update Mode: read-only


offsets.load.buffer.size
------------------------

Batch size for reading from the offsets segments when loading offsets into the
cache (soft-limit, overridden if records are too large).

Type: int
Default: 5242880
Valid Values: [1,...]
Importance: high
Update Mode: read-only


offsets.retention.check.interval.ms
-----------------------------------

Frequency at which to check for stale offsets

Type: long
Default: 600000 (10 minutes)
Valid Values: [1,...]
Importance: high
Update Mode: read-only


offsets.retention.minutes
-------------------------

For subscribed consumers, committed offset of a specific partition will be
expired and discarded when:

1) this retention period has elapsed after the consumer group loses all its
consumers (i.e. becomes empty);

2) this retention period has elapsed since the last time an offset is committed
for the partition and the group is no longer subscribed to the corresponding
topic.

For standalone consumers (using manual assignment), offsets will be
expired after this retention period has elapsed since the time of last commit.
Note that when a group is deleted via the delete-group request, its committed
offsets will also be deleted without extra retention period; also when a topic
is deleted via the delete-topic request, upon propagated metadata update any
group's committed offsets for that topic will also be deleted without extra
retention period.

Type: int
Default: 10080
Valid Values: [1,...]
Importance: high
Update Mode: read-only


offsets.topic.compression.codec
-------------------------------

Compression codec for the offsets topic - compression may be used to achieve
atomic commits.

Type: int
Default: 0
Valid Values:
Importance: high
Update Mode: read-only


offsets.topic.num.partitions
----------------------------

The number of partitions for the offset commit topic (should not change after
deployment).

Type: int
Default: 50
Valid Values: [1,...]
Importance: high
Update Mode: read-only


offsets.topic.replication.factor
--------------------------------

The replication factor for the offsets topic (set higher to ensure
availability). Internal topic creation will fail until the cluster size meets
this replication factor requirement.

Type: short
Default: 3
Valid Values: [1,...]
Importance: high
Update Mode: read-only


offsets.topic.segment.bytes
---------------------------

The offsets topic segment bytes should be kept relatively small in order to
facilitate faster log compaction and cache loads.

Type: int
Default: 104857600 (100 mebibytes)
Valid Values: [1,...]
Importance: high
Update Mode: read-only


process.roles
-------------

The roles that this process plays: 'broker', 'controller', or
'broker,controller' if it is both. This configuration is only applicable for
clusters in KRaft (Kafka Raft) mode (instead of ZooKeeper). Leave this config
undefined or empty for ZooKeeper clusters.

Type: list
Default:
Valid Values: [broker, controller]
Importance: high
Update Mode: read-only


queued.max.requests
-------------------

The number of queued requests allowed for data-plane, before blocking the
network threads

Type: int
Default: 500
Valid Values: [1,...]
Importance: high
Update Mode: read-only


replica.fetch.min.bytes
-----------------------

Minimum bytes expected for each fetch response. If not enough bytes, wait up to
replica.fetch.wait.max.ms (broker config).

Type: int
Default: 1
Valid Values:
Importance: high
Update Mode: read-only


replica.fetch.wait.max.ms
-------------------------

The maximum wait time for each fetcher request issued by follower replicas.
This value should always be less than the replica.lag.time.max.ms at all times
to prevent frequent shrinking of ISR for low throughput topics

Type: int
Default: 500
Valid Values:
Importance: high
Update Mode: read-only


replica.high.watermark.checkpoint.interval.ms
---------------------------------------------

The frequency with which the high watermark is saved out to disk

Type: long
Default: 5000 (5 seconds)
Valid Values:
Importance: high
Update Mode: read-only


replica.lag.time.max.ms
-----------------------

If a follower hasn't sent any fetch requests or hasn't consumed up to the
leaders log end offset for at least this time, the leader will remove the
follower from isr

Type: long
Default: 30000 (30 seconds)
Valid Values:
Importance: high
Update Mode: read-only


replica.socket.receive.buffer.bytes
-----------------------------------

The socket receive buffer for network requests to the leader for replicating
data

Type: int
Default: 65536 (64 kibibytes)
Valid Values:
Importance: high
Update Mode: read-only


replica.socket.timeout.ms
-------------------------

The socket timeout for network requests. Its value should be at least
replica.fetch.wait.max.ms

Type: int
Default: 30000 (30 seconds)
Valid Values:
Importance: high
Update Mode: read-only


request.timeout.ms
------------------

The configuration controls the maximum amount of time the client will wait for
the response of a request. If the response is not received before the timeout
elapses the client will resend the request if necessary or fail the request if
retries are exhausted.

Type: int
Default: 30000 (30 seconds)
Valid Values:
Importance: high
Update Mode: read-only


sasl.mechanism.controller.protocol
----------------------------------

SASL mechanism used for communication with controllers. Default is GSSAPI.

Type: string
Default: GSSAPI
Valid Values:
Importance: high
Update Mode: read-only


socket.receive.buffer.bytes
---------------------------

The SO_RCVBUF buffer of the socket server sockets. If the value is -1, the OS
default will be used.

Type: int
Default: 102400 (100 kibibytes)
Valid Values:
Importance: high
Update Mode: read-only


socket.request.max.bytes
------------------------

The maximum number of bytes in a socket request

Type: int
Default: 104857600 (100 mebibytes)
Valid Values: [1,...]
Importance: high
Update Mode: read-only


socket.send.buffer.bytes
------------------------

The SO_SNDBUF buffer of the socket server sockets. If the value is -1, the OS
default will be used.

Type: int
Default: 102400 (100 kibibytes)
Valid Values:
Importance: high
Update Mode: read-only


transaction.max.timeout.ms
--------------------------

The maximum allowed timeout for transactions. If a client’s requested
transaction time exceed this, then the broker will return an error in
InitProducerIdRequest. This prevents a client from too large of a timeout,
which can stall consumers reading from topics included in the transaction.

Type: int
Default: 900000 (15 minutes)
Valid Values: [1,...]
Importance: high
Update Mode: read-only


transaction.state.log.load.buffer.size
--------------------------------------

Batch size for reading from the transaction log segments when loading producer
ids and transactions into the cache (soft-limit, overridden if records are too
large).

Type: int
Default: 5242880
Valid Values: [1,...]
Importance: high
Update Mode: read-only


transaction.state.log.min.isr
-----------------------------

The minimum number of replicas that must acknowledge a write to transaction
topic in order to be considered successful.

Type: int
Default: 2
Valid Values: [1,...]
Importance: high
Update Mode: read-only


transaction.state.log.num.partitions
------------------------------------

The number of partitions for the transaction topic (should not change after
deployment).

Type: int
Default: 50
Valid Values: [1,...]
Importance: high
Update Mode: read-only


transaction.state.log.replication.factor
----------------------------------------

The replication factor for the transaction topic (set higher to ensure
availability). Internal topic creation will fail until the cluster size meets
this replication factor requirement.

Type: short
Default: 3
Valid Values: [1,...]
Importance: high
Update Mode: read-only


transaction.state.log.segment.bytes
-----------------------------------

The transaction topic segment bytes should be kept relatively small in order to
facilitate faster log compaction and cache loads

Type: int
Default: 104857600 (100 mebibytes)
Valid Values: [1,...]
Importance: high
Update Mode: read-only


transactional.id.expiration.ms
------------------------------

The time in ms that the transaction coordinator will wait without receiving any
transaction status updates for the current transaction before expiring its
transactional id. Transactional IDs will not expire while a the transaction is
still ongoing.

Type: int
Default: 604800000 (7 days)
Valid Values: [1,...]
Importance: high
Update Mode: read-only


unclean.leader.election.enable
------------------------------

Indicates whether to enable replicas not in the ISR set to be elected as leader
as a last resort, even though doing so may result in data loss

Type: boolean
Default: false
Valid Values:
Importance: high
Update Mode: cluster-wide


zookeeper.connect
-----------------

Specifies the ZooKeeper connection string in the form hostname:port where
host and port are the host and port of a ZooKeeper server. To allow connecting
through other ZooKeeper nodes when that ZooKeeper machine is down you can also
specify multiple hosts in the form
hostname1:port1,hostname2:port2,hostname3:port3.

The server can also have
a ZooKeeper chroot path as part of its ZooKeeper connection string which puts
its data under some path in the global ZooKeeper namespace. For example to give
a chroot path of /chroot/path you would give the connection string as
hostname1:port1,hostname2:port2,hostname3:port3/chroot/path.

Type: string
Default: null
Valid Values:
Importance: high
Update Mode: read-only


zookeeper.connection.timeout.ms
-------------------------------

The max time that the client waits to establish a connection to ZooKeeper. If
not set, the value in zookeeper.session.timeout.ms is used

Type: int
Default: null
Valid Values:
Importance: high
Update Mode: read-only


zookeeper.max.in.flight.requests
--------------------------------

The maximum number of unacknowledged requests the client will send to ZooKeeper
before blocking.

Type: int
Default: 10
Valid Values: [1,...]
Importance: high
Update Mode: read-only


zookeeper.metadata.migration.enable
-----------------------------------

Enable ZK to KRaft migration

Type: boolean
Default: false
Valid Values:
Importance: high
Update Mode: read-only


zookeeper.session.timeout.ms
----------------------------

Zookeeper session timeout

Type: int
Default: 18000 (18 seconds)
Valid Values:
Importance: high
Update Mode: read-only


zookeeper.set.acl
-----------------

Set client to use secure ACLs

Type: boolean
Default: false
Valid Values:
Importance: high
Update Mode: read-only


broker.heartbeat.interval.ms
----------------------------

The length of time in milliseconds between broker heartbeats. Used when running
in KRaft mode.

Type: int
Default: 2000 (2 seconds)
Valid Values:
Importance: medium
Update Mode: read-only


broker.id.generation.enable
---------------------------

Enable automatic broker id generation on the server. When enabled the value
configured for reserved.broker.max.id should be reviewed.

Type: boolean
Default: true
Valid Values:
Importance: medium
Update Mode: read-only


broker.rack
-----------

Rack of the broker. This will be used in rack aware replication assignment for
fault tolerance. Examples: RACK1, us-east-1d

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


broker.session.timeout.ms
-------------------------

The length of time in milliseconds that a broker lease lasts if no heartbeats
are made. Used when running in KRaft mode.

Type: int
Default: 9000 (9 seconds)
Valid Values:
Importance: medium
Update Mode: read-only


compression.gzip.level
----------------------

The compression level to use if compression.type is set to 'gzip'.

Type: int
Default: -1
Valid Values: [1,...,9] or -1
Importance: medium
Update Mode: cluster-wide


compression.lz4.level
---------------------

The compression level to use if compression.type is set to 'lz4'.

Type: int
Default: 9
Valid Values: [1,...,17]
Importance: medium
Update Mode: cluster-wide


compression.zstd.level
----------------------

The compression level to use if compression.type is set to 'zstd'.

Type: int
Default: 3
Valid Values: [-131072,...,22]
Importance: medium
Update Mode: cluster-wide


connections.max.idle.ms
-----------------------

Idle connections timeout: the server socket processor threads close the
connections that idle more than this

Type: long
Default: 600000 (10 minutes)
Valid Values:
Importance: medium
Update Mode: read-only


connections.max.reauth.ms
-------------------------

When explicitly set to a positive number (the default is 0, not a positive
number), a session lifetime that will not exceed the configured value will be
communicated to v2.2.0 or later clients when they authenticate. The broker will
disconnect any such connection that is not re-authenticated within the session
lifetime and that is then subsequently used for any purpose other than
re-authentication. Configuration names can optionally be prefixed with listener
prefix and SASL mechanism name in lower-case. For example,
listener.name.sasl_ssl.oauthbearer.connections.max.reauth.ms=3600000

Type: long
Default: 0
Valid Values:
Importance: medium
Update Mode: read-only


controlled.shutdown.enable
--------------------------

Enable controlled shutdown of the server.

Type: boolean
Default: true
Valid Values:
Importance: medium
Update Mode: read-only


controlled.shutdown.max.retries
-------------------------------

Controlled shutdown can fail for multiple reasons. This determines the number
of retries when such failure happens

Type: int
Default: 3
Valid Values:
Importance: medium
Update Mode: read-only


controlled.shutdown.retry.backoff.ms
------------------------------------

Before each retry, the system needs time to recover from the state that caused
the previous failure (Controller fail over, replica lag etc). This config
determines the amount of time to wait before retrying.

Type: long
Default: 5000 (5 seconds)
Valid Values:
Importance: medium
Update Mode: read-only


controller.quorum.append.linger.ms
----------------------------------

The duration in milliseconds that the leader will wait for writes to accumulate
before flushing them to disk.

Type: int
Default: 25
Valid Values:
Importance: medium
Update Mode: read-only


controller.quorum.request.timeout.ms
------------------------------------

The configuration controls the maximum amount of time the client will wait for
the response of a request. If the response is not received before the timeout
elapses the client will resend the request if necessary or fail the request if
retries are exhausted.

Type: int
Default: 2000 (2 seconds)
Valid Values:
Importance: medium
Update Mode: read-only


controller.socket.timeout.ms
----------------------------

The socket timeout for controller-to-broker channels.

Type: int
Default: 30000 (30 seconds)
Valid Values:
Importance: medium
Update Mode: read-only


default.replication.factor
--------------------------

The default replication factors for automatically created topics.

Type: int
Default: 1
Valid Values:
Importance: medium
Update Mode: read-only


delegation.token.expiry.time.ms
-------------------------------

The token validity time in milliseconds before the token needs to be renewed.
Default value 1 day.

Type: long
Default: 86400000 (1 day)
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


delegation.token.master.key
---------------------------

DEPRECATED: An alias for delegation.token.secret.key, which should be used
instead of this config.

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


delegation.token.max.lifetime.ms
--------------------------------

The token has a maximum lifetime beyond which it cannot be renewed anymore.
Default value 7 days.

Type: long
Default: 604800000 (7 days)
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


delegation.token.secret.key
---------------------------

Secret key to generate and verify delegation tokens. The same key must be
configured across all the brokers. If using Kafka with KRaft, the key must also
be set across all controllers. If the key is not set or set to empty string,
brokers will disable the delegation token support.

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


delete.records.purgatory.purge.interval.requests
------------------------------------------------

The purge interval (in number of requests) of the delete records request
purgatory

Type: int
Default: 1
Valid Values:
Importance: medium
Update Mode: read-only


fetch.max.bytes
---------------

The maximum number of bytes we will return for a fetch request. Must be at
least 1024.

Type: int
Default: 57671680 (55 mebibytes)
Valid Values: [1024,...]
Importance: medium
Update Mode: read-only


fetch.purgatory.purge.interval.requests
---------------------------------------

The purge interval (in number of requests) of the fetch request purgatory

Type: int
Default: 1000
Valid Values:
Importance: medium
Update Mode: read-only


group.consumer.assignors
------------------------

The server side assignors as a list of full class names. The first one in the
list is considered as the default assignor to be used in the case where the
consumer does not specify an assignor.

Type: list
Default: org.apache.kafka.coordinator.group.assignor.UniformAssignor,org.apache.kafka.coordinator.group.assignor.RangeAssignor
Valid Values:
Importance: medium
Update Mode: read-only


group.consumer.heartbeat.interval.ms
------------------------------------

The heartbeat interval given to the members of a consumer group.

Type: int
Default: 5000 (5 seconds)
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


group.consumer.max.heartbeat.interval.ms
----------------------------------------

The maximum heartbeat interval for registered consumers.

Type: int
Default: 15000 (15 seconds)
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


group.consumer.max.session.timeout.ms
-------------------------------------

The maximum allowed session timeout for registered consumers.

Type: int
Default: 60000 (1 minute)
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


group.consumer.max.size
-----------------------

The maximum number of consumers that a single consumer group can accommodate.
This value will only impact the new consumer coordinator. To configure the
classic consumer coordinator check group.max.size instead.

Type: int
Default: 2147483647
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


group.consumer.migration.policy
-------------------------------

The config that enables converting the non-empty classic group using the
consumer embedded protocol to the non-empty consumer group using the consumer
group protocol and vice versa; conversions of empty groups in both directions
are always enabled regardless of this policy. bidirectional: both upgrade from
classic group to consumer group and downgrade from consumer group to classic
group are enabled, upgrade: only upgrade from classic group to consumer group
is enabled, downgrade: only downgrade from consumer group to classic group is
enabled, disabled: neither upgrade nor downgrade is enabled.

Type: string
Default: disabled
Valid Values: (case insensitive) [DISABLED, DOWNGRADE, UPGRADE, BIDIRECTIONAL]
Importance: medium
Update Mode: read-only


group.consumer.min.heartbeat.interval.ms
----------------------------------------

The minimum heartbeat interval for registered consumers.

Type: int
Default: 5000 (5 seconds)
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


group.consumer.min.session.timeout.ms
-------------------------------------

The minimum allowed session timeout for registered consumers.

Type: int
Default: 45000 (45 seconds)
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


group.consumer.session.timeout.ms
---------------------------------

The timeout to detect client failures when using the consumer group protocol.

Type: int
Default: 45000 (45 seconds)
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


group.coordinator.append.linger.ms
----------------------------------

The duration in milliseconds that the coordinator will wait for writes to
accumulate before flushing them to disk. Transactional writes are not
accumulated.

Type: int
Default: 10
Valid Values: [0,...]
Importance: medium
Update Mode: read-only


group.coordinator.rebalance.protocols
-------------------------------------

The list of enabled rebalance protocols. Supported protocols:
consumer,classic,unknown. The consumer rebalance protocol is in early access
and therefore must not be used in production.

Type: list
Default: classic
Valid Values: [consumer, classic, unknown]
Importance: medium
Update Mode: read-only


group.coordinator.threads
-------------------------

The number of threads used by the group coordinator.

Type: int
Default: 1
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


group.initial.rebalance.delay.ms
--------------------------------

The amount of time the group coordinator will wait for more consumers to join a
new group before performing the first rebalance. A longer delay means
potentially fewer rebalances, but increases the time until processing begins.

Type: int
Default: 3000 (3 seconds)
Valid Values:
Importance: medium
Update Mode: read-only


group.max.session.timeout.ms
----------------------------

The maximum allowed session timeout for registered consumers. Longer timeouts
give consumers more time to process messages in between heartbeats at the cost
of a longer time to detect failures.

Type: int
Default: 1800000 (30 minutes)
Valid Values:
Importance: medium
Update Mode: read-only


group.max.size
--------------

The maximum number of consumers that a single consumer group can accommodate.

Type: int
Default: 2147483647
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


group.min.session.timeout.ms
----------------------------

The minimum allowed session timeout for registered consumers. Shorter timeouts
result in quicker failure detection at the cost of more frequent consumer
heartbeating, which can overwhelm broker resources.

Type: int
Default: 6000 (6 seconds)
Valid Values:
Importance: medium
Update Mode: read-only


initial.broker.registration.timeout.ms
--------------------------------------

When initially registering with the controller quorum, the number of
milliseconds to wait before declaring failure and exiting the broker process.

Type: int
Default: 60000 (1 minute)
Valid Values:
Importance: medium
Update Mode: read-only


inter.broker.listener.name
--------------------------

Name of listener used for communication between brokers. If this is unset, the
listener name is defined by security.inter.broker.protocolIt is an error to set
this and security.inter.broker.protocol properties at the same time.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


inter.broker.protocol.version
-----------------------------

Specify which version of the inter-broker protocol will be used.

. This is
typically bumped after all brokers were upgraded to a new version.

 Example
of some valid values are: 0.8.0, 0.8.1, 0.8.1.1, 0.8.2, 0.8.2.0, 0.8.2.1,
0.9.0.0, 0.9.0.1 Check MetadataVersion for the full list.

Type: string
Default: 3.8-IV0
Valid Values: [0.8.0, 0.8.1, 0.8.2, 0.9.0, 0.10.0-IV0, 0.10.0-IV1, 0.10.1-IV0, 0.10.1-IV1, 0.10.1-IV2, 0.10.2-IV0, 0.11.0-IV0, 0.11.0-IV1, 0.11.0-IV2, 1.0-IV0, 1.1-IV0, 2.0-IV0, 2.0-IV1, 2.1-IV0, 2.1-IV1, 2.1-IV2, 2.2-IV0, 2.2-IV1, 2.3-IV0, 2.3-IV1, 2.4-IV0, 2.4-IV1, 2.5-IV0, 2.6-IV0, 2.7-IV0, 2.7-IV1, 2.7-IV2, 2.8-IV0, 2.8-IV1, 3.0-IV0, 3.0-IV1, 3.1-IV0, 3.2-IV0, 3.3-IV0, 3.3-IV1, 3.3-IV2, 3.3-IV3, 3.4-IV0, 3.5-IV0, 3.5-IV1, 3.5-IV2, 3.6-IV0, 3.6-IV1, 3.6-IV2, 3.7-IV0, 3.7-IV1, 3.7-IV2, 3.7-IV3, 3.7-IV4, 3.8-IV0, 3.9-IV0]
Importance: medium
Update Mode: read-only


log.cleaner.backoff.ms
----------------------

The amount of time to sleep when there are no logs to clean

Type: long
Default: 15000 (15 seconds)
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


log.cleaner.dedupe.buffer.size
------------------------------

The total memory used for log deduplication across all cleaner threads

Type: long
Default: 134217728
Valid Values:
Importance: medium
Update Mode: cluster-wide


log.cleaner.delete.retention.ms
-------------------------------

The amount of time to retain tombstone message markers for log compacted
topics. This setting also gives a bound on the time in which a consumer must
complete a read if they begin from offset 0 to ensure that they get a valid
snapshot of the final stage (otherwise tombstones messages may be collected
before a consumer completes their scan).

Type: long
Default: 86400000 (1 day)
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


log.cleaner.enable
------------------

Enable the log cleaner process to run on the server. Should be enabled if using
any topics with a cleanup.policy=compact including the internal offsets topic.
If disabled those topics will not be compacted and continually grow in size.

Type: boolean
Default: true
Valid Values:
Importance: medium
Update Mode: read-only


log.cleaner.io.buffer.load.factor
---------------------------------

Log cleaner dedupe buffer load factor. The percentage full the dedupe buffer
can become. A higher value will allow more log to be cleaned at once but will
lead to more hash collisions

Type: double
Default: 0.9
Valid Values:
Importance: medium
Update Mode: cluster-wide


log.cleaner.io.buffer.size
--------------------------

The total memory used for log cleaner I/O buffers across all cleaner threads

Type: int
Default: 524288
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


log.cleaner.io.max.bytes.per.second
-----------------------------------

The log cleaner will be throttled so that the sum of its read and write i/o
will be less than this value on average

Type: double
Default: 1.7976931348623157E308
Valid Values:
Importance: medium
Update Mode: cluster-wide


log.cleaner.max.compaction.lag.ms
---------------------------------

The maximum time a message will remain ineligible for compaction in the log.
Only applicable for logs that are being compacted.

Type: long
Default: 9223372036854775807
Valid Values: [1,...]
Importance: medium
Update Mode: cluster-wide


log.cleaner.min.cleanable.ratio
-------------------------------

The minimum ratio of dirty log to total log for a log to eligible for cleaning.
If the log.cleaner.max.compaction.lag.ms or the
log.cleaner.min.compaction.lag.ms configurations are also specified, then the
log compactor considers the log eligible for compaction as soon as either: (i)
the dirty ratio threshold has been met and the log has had dirty (uncompacted)
records for at least the log.cleaner.min.compaction.lag.ms duration, or (ii) if
the log has had dirty (uncompacted) records for at most the
log.cleaner.max.compaction.lag.ms period.

Type: double
Default: 0.5
Valid Values: [0,...,1]
Importance: medium
Update Mode: cluster-wide


log.cleaner.min.compaction.lag.ms
---------------------------------

The minimum time a message will remain uncompacted in the log. Only applicable
for logs that are being compacted.

Type: long
Default: 0
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


log.cleaner.threads
-------------------

The number of background threads to use for log cleaning

Type: int
Default: 1
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


log.cleanup.policy
------------------

The default cleanup policy for segments beyond the retention window. A comma
separated list of valid policies. Valid policies are: delete and
compact

Type: list
Default: delete
Valid Values: [compact, delete]
Importance: medium
Update Mode: cluster-wide


log.index.interval.bytes
------------------------

The interval with which we add an entry to the offset index.

Type: int
Default: 4096 (4 kibibytes)
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


log.index.size.max.bytes
------------------------

The maximum size in bytes of the offset index

Type: int
Default: 10485760 (10 mebibytes)
Valid Values: [4,...]
Importance: medium
Update Mode: cluster-wide


log.local.retention.bytes
-------------------------

The maximum size of local log segments that can grow for a partition before it
gets eligible for deletion. Default value is -2, it represents
`log.retention.bytes` value to be used. The effective value should always be
less than or equal to `log.retention.bytes` value.

Type: long
Default: -2
Valid Values: [-2,...]
Importance: medium
Update Mode: cluster-wide


log.local.retention.ms
----------------------

The number of milliseconds to keep the local log segments before it gets
eligible for deletion. Default value is -2, it represents `log.retention.ms`
value is to be used. The effective value should always be less than or equal to
`log.retention.ms` value.

Type: long
Default: -2
Valid Values: [-2,...]
Importance: medium
Update Mode: cluster-wide


log.message.format.version
--------------------------

Specify the message format version the broker will use to append messages to
the logs. The value should be a valid MetadataVersion. Some examples are:
0.8.2, 0.9.0.0, 0.10.0, check MetadataVersion for more details. By setting a
particular message format version, the user is certifying that all the existing
messages on disk are smaller or equal than the specified version. Setting this
value incorrectly will cause consumers with older versions to break as they
will receive messages with a format that they don't understand.

Type: string
Default: 3.0-IV1
Valid Values: [0.8.0, 0.8.1, 0.8.2, 0.9.0, 0.10.0-IV0, 0.10.0-IV1, 0.10.1-IV0, 0.10.1-IV1, 0.10.1-IV2, 0.10.2-IV0, 0.11.0-IV0, 0.11.0-IV1, 0.11.0-IV2, 1.0-IV0, 1.1-IV0, 2.0-IV0, 2.0-IV1, 2.1-IV0, 2.1-IV1, 2.1-IV2, 2.2-IV0, 2.2-IV1, 2.3-IV0, 2.3-IV1, 2.4-IV0, 2.4-IV1, 2.5-IV0, 2.6-IV0, 2.7-IV0, 2.7-IV1, 2.7-IV2, 2.8-IV0, 2.8-IV1, 3.0-IV0, 3.0-IV1, 3.1-IV0, 3.2-IV0, 3.3-IV0, 3.3-IV1, 3.3-IV2, 3.3-IV3, 3.4-IV0, 3.5-IV0, 3.5-IV1, 3.5-IV2, 3.6-IV0, 3.6-IV1, 3.6-IV2, 3.7-IV0, 3.7-IV1, 3.7-IV2, 3.7-IV3, 3.7-IV4, 3.8-IV0, 3.9-IV0]
Importance: medium
Update Mode: read-only


log.message.timestamp.after.max.ms
----------------------------------

This configuration sets the allowable timestamp difference between the message
timestamp and the broker's timestamp. The message timestamp can be later than
or equal to the broker's timestamp, with the maximum allowable difference
determined by the value set in this configuration. If
log.message.timestamp.type=CreateTime, the message will be rejected if the
difference in timestamps exceeds this specified threshold. This configuration
is ignored if log.message.timestamp.type=LogAppendTime.

Type: long
Default: 9223372036854775807
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


log.message.timestamp.before.max.ms
-----------------------------------

This configuration sets the allowable timestamp difference between the broker's
timestamp and the message timestamp. The message timestamp can be earlier than
or equal to the broker's timestamp, with the maximum allowable difference
determined by the value set in this configuration. If
log.message.timestamp.type=CreateTime, the message will be rejected if the
difference in timestamps exceeds this specified threshold. This configuration
is ignored if log.message.timestamp.type=LogAppendTime.

Type: long
Default: 9223372036854775807
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


log.message.timestamp.difference.max.ms
---------------------------------------

[DEPRECATED] The maximum difference allowed between the timestamp when a
broker receives a message and the timestamp specified in the message. If
log.message.timestamp.type=CreateTime, a message will be rejected if the
difference in timestamp exceeds this threshold. This configuration is ignored
if log.message.timestamp.type=LogAppendTime.The maximum timestamp difference
    allowed should be no greater than log.retention.ms to avoid unnecessarily
    frequent log rolling.

Type: long
Default: 9223372036854775807
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


log.message.timestamp.type
--------------------------

Define whether the timestamp in the message is message create time or log
append time. The value should be either CreateTime or LogAppendTime.

Type: string
Default: CreateTime
Valid Values: [CreateTime, LogAppendTime]
Importance: medium
Update Mode: cluster-wide


log.preallocate
---------------

Should pre allocate file when create new segment? If you are using Kafka on
Windows, you probably need to set it to true.

Type: boolean
Default: false
Valid Values:
Importance: medium
Update Mode: cluster-wide


log.retention.check.interval.ms
-------------------------------

The frequency in milliseconds that the log cleaner checks whether any log is
eligible for deletion

Type: long
Default: 300000 (5 minutes)
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


max.connection.creation.rate
----------------------------

The maximum connection creation rate we allow in the broker at any time.
Listener-level limits may also be configured by prefixing the config name with
the listener prefix, for example,
listener.name.internal.max.connection.creation.rate.Broker-wide connection
rate limit should be configured based on broker capacity while listener limits
should be configured based on application requirements. New connections will be
throttled if either the listener or the broker limit is reached, with the
exception of inter-broker listener. Connections on the inter-broker listener
will be throttled only when the listener-level rate limit is reached.

Type: int
Default: 2147483647
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


max.connections
---------------

The maximum number of connections we allow in the broker at any time. This
limit is applied in addition to any per-ip limits configured using
max.connections.per.ip. Listener-level limits may also be configured by
prefixing the config name with the listener prefix, for example,
listener.name.internal.max.connections.per.ip. Broker-wide limit should be
configured based on broker capacity while listener limits should be configured
based on application requirements. New connections are blocked if either the
listener or broker limit is reached. Connections on the inter-broker listener
are permitted even if broker-wide limit is reached. The least recently used
connection on another listener will be closed in this case.

Type: int
Default: 2147483647
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


max.connections.per.ip
----------------------

The maximum number of connections we allow from each ip address. This can be
set to 0 if there are overrides configured using
max.connections.per.ip.overrides property. New connections from the ip address
are dropped if the limit is reached.

Type: int
Default: 2147483647
Valid Values: [0,...]
Importance: medium
Update Mode: cluster-wide


max.connections.per.ip.overrides
--------------------------------

A comma-separated list of per-ip or hostname overrides to the default maximum
number of connections. An example value is hostName:100,127.0.0.1:200

Type: string
Default:
Valid Values:
Importance: medium
Update Mode: cluster-wide


max.incremental.fetch.session.cache.slots
-----------------------------------------

The maximum number of total incremental fetch sessions that we will maintain.
FetchSessionCache is sharded into 8 shards and the limit is equally divided
among all shards. Sessions are allocated to each shard in round-robin. Only
entries within a shard are considered eligible for eviction.

Type: int
Default: 1000
Valid Values: [0,...]
Importance: medium
Update Mode: read-only


max.request.partition.size.limit
--------------------------------

The maximum number of partitions can be served in one request.

Type: int
Default: 2000
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


num.partitions
--------------

The default number of log partitions per topic

Type: int
Default: 1
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


password.encoder.old.secret
---------------------------

The old secret that was used for encoding dynamically configured passwords.
This is required only when the secret is updated. If specified, all dynamically
encoded passwords are decoded using this old secret and re-encoded using
password.encoder.secret when broker starts up.

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


password.encoder.secret
-----------------------

The secret used for encoding dynamically configured passwords for this broker.

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


principal.builder.class
-----------------------

The fully qualified name of a class that implements the KafkaPrincipalBuilder
interface, which is used to build the KafkaPrincipal object used during
authorization. If no principal builder is defined, the default behavior depends
on the security protocol in use. For SSL authentication, the principal will be
derived using the rules defined by ssl.principal.mapping.rules applied on the
distinguished name from the client certificate if one is provided; otherwise,
if client authentication is not required, the principal name will be ANONYMOUS.
    For SASL authentication, the principal will be derived using the rules
    defined by sasl.kerberos.principal.to.local.rules if GSSAPI is in use,
    and the SASL authentication ID for other mechanisms. For PLAINTEXT, the
    principal will be ANONYMOUS.

Type: class
Default: org.apache.kafka.common.security.authenticator.DefaultKafkaPrincipalBuilder
Valid Values:
Importance: medium
Update Mode: per-broker


producer.purgatory.purge.interval.requests
------------------------------------------

The purge interval (in number of requests) of the producer request purgatory

Type: int
Default: 1000
Valid Values:
Importance: medium
Update Mode: read-only


queued.max.request.bytes
------------------------

The number of queued bytes allowed before no more requests are read

Type: long
Default: -1
Valid Values:
Importance: medium
Update Mode: read-only


remote.fetch.max.wait.ms
------------------------

The maximum amount of time the server will wait before answering the remote
fetch request

Type: int
Default: 500
Valid Values: [1,...]
Importance: medium
Update Mode: cluster-wide


remote.log.manager.copy.max.bytes.per.second
--------------------------------------------

The maximum number of bytes that can be copied from local storage to remote
storage per second. This is a global limit for all the partitions that are
being copied from local storage to remote storage. The default value is
Long.MAX_VALUE, which means there is no limit on the number of bytes that can
be copied per second.

Type: long
Default: 9223372036854775807
Valid Values: [1,...]
Importance: medium
Update Mode: cluster-wide


remote.log.manager.copy.quota.window.num
----------------------------------------

The number of samples to retain in memory for remote copy quota management. The
default value is 11, which means there are 10 whole windows + 1 current window.

Type: int
Default: 11
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


remote.log.manager.copy.quota.window.size.seconds
-------------------------------------------------

The time span of each sample for remote copy quota management. The default
value is 1 second.

Type: int
Default: 1
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


remote.log.manager.fetch.max.bytes.per.second
---------------------------------------------

The maximum number of bytes that can be fetched from remote storage to local
storage per second. This is a global limit for all the partitions that are
being fetched from remote storage to local storage. The default value is
Long.MAX_VALUE, which means there is no limit on the number of bytes that can
be fetched per second.

Type: long
Default: 9223372036854775807
Valid Values: [1,...]
Importance: medium
Update Mode: cluster-wide


remote.log.manager.fetch.quota.window.num
-----------------------------------------

The number of samples to retain in memory for remote fetch quota management.
The default value is 11, which means there are 10 whole windows + 1 current
window.

Type: int
Default: 11
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


remote.log.manager.fetch.quota.window.size.seconds
--------------------------------------------------

The time span of each sample for remote fetch quota management. The default
value is 1 second.

Type: int
Default: 1
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


remote.log.manager.thread.pool.size
-----------------------------------

Size of the thread pool used in scheduling tasks to copy segments, fetch remote
log indexes and clean up remote log segments.

Type: int
Default: 10
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


remote.log.metadata.manager.class.name
--------------------------------------

Fully qualified class name of `RemoteLogMetadataManager` implementation.

Type: string
Default: org.apache.kafka.server.log.remote.metadata.storage.TopicBasedRemoteLogMetadataManager
Valid Values: non-empty string
Importance: medium
Update Mode: read-only


remote.log.metadata.manager.class.path
--------------------------------------

Class path of the `RemoteLogMetadataManager` implementation. If specified,
the RemoteLogMetadataManager implementation and its dependent libraries will be
loaded by a dedicated classloader which searches this class path before the
Kafka broker class path. The syntax of this parameter is same as the standard
Java class path string.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


remote.log.metadata.manager.impl.prefix
---------------------------------------

Prefix used for properties to be passed to RemoteLogMetadataManager
implementation. For example this value can be `rlmm.config.`.

Type: string
Default: rlmm.config.
Valid Values: non-empty string
Importance: medium
Update Mode: read-only


remote.log.metadata.manager.listener.name
-----------------------------------------

Listener name of the local broker to which it should get connected if needed by
RemoteLogMetadataManager implementation.

Type: string
Default: null
Valid Values: non-empty string
Importance: medium
Update Mode: read-only


remote.log.reader.max.pending.tasks
-----------------------------------

Maximum remote log reader thread pool task queue size. If the task queue is
full, fetch requests are served with an error.

Type: int
Default: 100
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


remote.log.reader.threads
-------------------------

Size of the thread pool that is allocated for handling remote log reads.

Type: int
Default: 10
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


remote.log.storage.manager.class.name
-------------------------------------

Fully qualified class name of `RemoteStorageManager` implementation.

Type: string
Default: null
Valid Values: non-empty string
Importance: medium
Update Mode: read-only


remote.log.storage.manager.class.path
-------------------------------------

Class path of the `RemoteStorageManager` implementation. If specified, the
RemoteStorageManager implementation and its dependent libraries will be loaded
by a dedicated classloader which searches this class path before the Kafka
broker class path. The syntax of this parameter is same as the standard Java
class path string.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


remote.log.storage.manager.impl.prefix
--------------------------------------

Prefix used for properties to be passed to RemoteStorageManager implementation.
For example this value can be `rsm.config.`.

Type: string
Default: rsm.config.
Valid Values: non-empty string
Importance: medium
Update Mode: read-only


remote.log.storage.system.enable
--------------------------------

Whether to enable tiered storage functionality in a broker or not. Valid values
are `true` or `false` and the default value is false. When it is true
broker starts all the services required for the tiered storage functionality.

Type: boolean
Default: false
Valid Values:
Importance: medium
Update Mode: read-only


replica.fetch.backoff.ms
------------------------

The amount of time to sleep when fetch partition error occurs.

Type: int
Default: 1000 (1 second)
Valid Values: [0,...]
Importance: medium
Update Mode: read-only


replica.fetch.max.bytes
-----------------------

The number of bytes of messages to attempt to fetch for each partition. This is
not an absolute maximum, if the first record batch in the first non-empty
partition of the fetch is larger than this value, the record batch will still
be returned to ensure that progress can be made. The maximum record batch size
accepted by the broker is defined via message.max.bytes (broker config) or
max.message.bytes (topic config).

Type: int
Default: 1048576 (1 mebibyte)
Valid Values: [0,...]
Importance: medium
Update Mode: read-only


replica.fetch.response.max.bytes
--------------------------------

Maximum bytes expected for the entire fetch response. Records are fetched in
batches, and if the first record batch in the first non-empty partition of the
fetch is larger than this value, the record batch will still be returned to
ensure that progress can be made. As such, this is not an absolute maximum. The
maximum record batch size accepted by the broker is defined via
message.max.bytes (broker config) or max.message.bytes (topic config).

Type: int
Default: 10485760 (10 mebibytes)
Valid Values: [0,...]
Importance: medium
Update Mode: read-only


replica.selector.class
----------------------

The fully qualified class name that implements ReplicaSelector. This is used by
the broker to find the preferred read replica. By default, we use an
implementation that returns the leader.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


reserved.broker.max.id
----------------------

Max number that can be used for a broker.id

Type: int
Default: 1000
Valid Values: [0,...]
Importance: medium
Update Mode: read-only


sasl.client.callback.handler.class
----------------------------------

The fully qualified name of a SASL client callback handler class that
implements the AuthenticateCallbackHandler interface.

Type: class
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


sasl.enabled.mechanisms
-----------------------

The list of SASL mechanisms enabled in the Kafka server. The list may contain
any mechanism for which a security provider is available. Only GSSAPI is
enabled by default.

Type: list
Default: GSSAPI
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.jaas.config
----------------

JAAS login context parameters for SASL connections in the format used by JAAS
configuration files. JAAS configuration file format is described <a
href=https://docs.oracle.com/javase/8/docs/technotes/guides/security/jgss/tutorials/LoginConfigFile.html>here</a>.
The format for the value is: loginModuleClass controlFlag
(optionName=optionValue);. For brokers, the config must be prefixed with
listener prefix and SASL mechanism name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.jaas.config=com.example.ScramLoginModule
required;

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.kerberos.kinit.cmd
-----------------------

Kerberos kinit command path.

Type: string
Default: /usr/bin/kinit
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.kerberos.min.time.before.relogin
-------------------------------------

Login thread sleep time between refresh attempts.

Type: long
Default: 60000
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.kerberos.principal.to.local.rules
--------------------------------------

A list of rules for mapping from principal names to short names (typically
operating system usernames). The rules are evaluated in order and the first
rule that matches a principal name is used to map it to a short name. Any later
rules in the list are ignored. By default, principal names of the form
{username}/{hostname}@{REALM} are mapped to {username}. For more details on
the format please see <a href=#security_authz> security authorization and
acls</a>. Note that this configuration is ignored if an extension of
KafkaPrincipalBuilder is provided by the principal.builder.class
configuration.

Type: list
Default: DEFAULT
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.kerberos.service.name
--------------------------

The Kerberos principal name that Kafka runs as. This can be defined either in
Kafka's JAAS config or in Kafka's config.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.kerberos.ticket.renew.jitter
---------------------------------

Percentage of random jitter added to the renewal time.

Type: double
Default: 0.05
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.kerberos.ticket.renew.window.factor
----------------------------------------

Login thread will sleep until the specified window factor of time from last
refresh to ticket's expiry has been reached, at which time it will try to renew
the ticket.

Type: double
Default: 0.8
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.login.callback.handler.class
---------------------------------

The fully qualified name of a SASL login callback handler class that implements
the AuthenticateCallbackHandler interface. For brokers, login callback handler
config must be prefixed with listener prefix and SASL mechanism name in
lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.callback.handler.class=com.example.CustomScramLoginCallbackHandler

Type: class
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


sasl.login.class
----------------

The fully qualified name of a class that implements the Login interface. For
brokers, login config must be prefixed with listener prefix and SASL mechanism
name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.class=com.example.CustomScramLogin

Type: class
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


sasl.login.refresh.buffer.seconds
---------------------------------

The amount of buffer time before credential expiration to maintain when
refreshing a credential, in seconds. If a refresh would otherwise occur closer
to expiration than the number of buffer seconds then the refresh will be moved
up to maintain as much of the buffer time as possible. Legal values are between
0 and 3600 (1 hour); a default value of 300 (5 minutes) is used if no value is
specified. This value and sasl.login.refresh.min.period.seconds are both
ignored if their sum exceeds the remaining lifetime of a credential. Currently
applies only to OAUTHBEARER.

Type: short
Default: 300
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.login.refresh.min.period.seconds
-------------------------------------

The desired minimum time for the login refresh thread to wait before refreshing
a credential, in seconds. Legal values are between 0 and 900 (15 minutes); a
default value of 60 (1 minute) is used if no value is specified. This value and
sasl.login.refresh.buffer.seconds are both ignored if their sum exceeds the
remaining lifetime of a credential. Currently applies only to OAUTHBEARER.

Type: short
Default: 60
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.login.refresh.window.factor
--------------------------------

Login refresh thread will sleep until the specified window factor relative to
the credential's lifetime has been reached, at which time it will try to
refresh the credential. Legal values are between 0.5 (50%) and 1.0 (100%)
inclusive; a default value of 0.8 (80%) is used if no value is specified.
Currently applies only to OAUTHBEARER.

Type: double
Default: 0.8
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.login.refresh.window.jitter
--------------------------------

The maximum amount of random jitter relative to the credential's lifetime that
is added to the login refresh thread's sleep time. Legal values are between 0
and 0.25 (25%) inclusive; a default value of 0.05 (5%) is used if no value is
specified. Currently applies only to OAUTHBEARER.

Type: double
Default: 0.05
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.mechanism.inter.broker.protocol
------------------------------------

SASL mechanism used for inter-broker communication. Default is GSSAPI.

Type: string
Default: GSSAPI
Valid Values:
Importance: medium
Update Mode: per-broker


sasl.oauthbearer.jwks.endpoint.url
----------------------------------

The OAuth/OIDC provider URL from which the provider's <a
href=https://datatracker.ietf.org/doc/html/rfc7517#section-5>JWKS (JSON Web
Key Set)</a> can be retrieved. The URL can be HTTP(S)-based or file-based. If
the URL is HTTP(S)-based, the JWKS data will be retrieved from the OAuth/OIDC
provider via the configured URL on broker startup. All then-current keys will
be cached on the broker for incoming requests. If an authentication request is
received for a JWT that includes a kid header claim value that isn't yet in
the cache, the JWKS endpoint will be queried again on demand. However, the
broker polls the URL every sasl.oauthbearer.jwks.endpoint.refresh.ms
milliseconds to refresh the cache with any forthcoming keys before any JWT
requests that include them are received. If the URL is file-based, the broker
will load the JWKS file from a configured location on startup. In the event
that the JWT includes a kid header value that isn't in the JWKS file, the
broker will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


sasl.oauthbearer.token.endpoint.url
-----------------------------------

The URL for the OAuth/OIDC identity provider. If the URL is HTTP(S)-based, it
is the issuer's token endpoint URL to which requests will be made to login
based on the configuration in sasl.jaas.config. If the URL is file-based, it
specifies a file containing an access token (in JWT serialized form) issued by
the OAuth/OIDC identity provider to use for authorization.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


sasl.server.callback.handler.class
----------------------------------

The fully qualified name of a SASL server callback handler class that
implements the AuthenticateCallbackHandler interface. Server callback handlers
must be prefixed with listener prefix and SASL mechanism name in lower-case.
For example,
listener.name.sasl_ssl.plain.sasl.server.callback.handler.class=com.example.CustomPlainCallbackHandler.

Type: class
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


sasl.server.max.receive.size
----------------------------

The maximum receive size allowed before and during initial SASL authentication.
Default receive size is 512KB. GSSAPI limits requests to 64K, but we allow upto
512KB by default for custom SASL mechanisms. In practice, PLAIN, SCRAM and
OAUTH mechanisms can use much smaller limits.

Type: int
Default: 524288
Valid Values:
Importance: medium
Update Mode: read-only


security.inter.broker.protocol
------------------------------

Security protocol used to communicate between brokers. Valid values are:
PLAINTEXT, SSL, SASL_PLAINTEXT, SASL_SSL. It is an error to set this and
inter.broker.listener.name properties at the same time.

Type: string
Default: PLAINTEXT
Valid Values: [PLAINTEXT, SSL, SASL_PLAINTEXT, SASL_SSL]
Importance: medium
Update Mode: read-only


socket.connection.setup.timeout.max.ms
--------------------------------------

The maximum amount of time the client will wait for the socket connection to be
established. The connection setup timeout will increase exponentially for each
consecutive connection failure up to this maximum. To avoid connection storms,
a randomization factor of 0.2 will be applied to the timeout resulting in a
random range between 20% below and 20% above the computed value.

Type: long
Default: 30000 (30 seconds)
Valid Values:
Importance: medium
Update Mode: read-only


socket.connection.setup.timeout.ms
----------------------------------

The amount of time the client will wait for the socket connection to be
established. If the connection is not built before the timeout elapses, clients
will close the socket channel. This value is the initial backoff value and will
increase exponentially for each consecutive connection failure, up to the
socket.connection.setup.timeout.max.ms value.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: medium
Update Mode: read-only


socket.listen.backlog.size
--------------------------

The maximum number of pending connections on the socket. In Linux, you may also
need to configure somaxconn and tcp_max_syn_backlog kernel parameters
accordingly to make the configuration takes effect.

Type: int
Default: 50
Valid Values: [1,...]
Importance: medium
Update Mode: read-only


ssl.cipher.suites
-----------------

A list of cipher suites. This is a named combination of authentication,
encryption, MAC and key exchange algorithm used to negotiate the security
settings for a network connection using TLS or SSL network protocol. By default
all the available cipher suites are supported.

Type: list
Default:
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.client.auth
---------------

Configures kafka broker to request client authentication. The following
settings are common: <ul> <li>ssl.client.auth=required If set to required
client authentication is required. <li>ssl.client.auth=requested This means
client authentication is optional. unlike required, if this option is set
client can choose not to provide authentication information about itself
<li>ssl.client.auth=none This means client authentication is not needed.</ul>

Type: string
Default: none
Valid Values: [required, requested, none]
Importance: medium
Update Mode: per-broker


ssl.enabled.protocols
---------------------

The list of protocols enabled for SSL connections. The default is
'TLSv1.2,TLSv1.3' when running with Java 11 or newer, 'TLSv1.2' otherwise. With
the default value for Java 11, clients and servers will prefer TLSv1.3 if both
support it and fallback to TLSv1.2 otherwise (assuming both support at least
TLSv1.2). This default should be fine for most cases. Also see the config
documentation for `ssl.protocol`.

Type: list
Default: TLSv1.2,TLSv1.3
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.key.password
----------------

The password of the private key in the key store file or the PEM key specified
in 'ssl.keystore.key'.

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.keymanager.algorithm
------------------------

The algorithm used by key manager factory for SSL connections. Default value is
the key manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: SunX509
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.keystore.certificate.chain
------------------------------

Certificate chain in the format specified by 'ssl.keystore.type'. Default SSL
engine factory supports only PEM format with a list of X.509 certificates

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.keystore.key
----------------

Private key in the format specified by 'ssl.keystore.type'. Default SSL engine
factory supports only PEM format with PKCS#8 keys. If the key is encrypted, key
password must be specified using 'ssl.key.password'

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.keystore.location
---------------------

The location of the key store file. This is optional for client and can be used
for two-way authentication for client.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.keystore.password
---------------------

The store password for the key store file. This is optional for client and only
needed if 'ssl.keystore.location' is configured. Key store password is not
supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.keystore.type
-----------------

The file format of the key store file. This is optional for client. The values
currently supported by the default `ssl.engine.factory.class` are [JKS,
PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.protocol
------------

The SSL protocol used to generate the SSLContext. The default is 'TLSv1.3' when
running with Java 11 or newer, 'TLSv1.2' otherwise. This value should be fine
for most use cases. Allowed values in recent JVMs are 'TLSv1.2' and 'TLSv1.3'.
    'TLS', 'TLSv1.1', 'SSL', 'SSLv2' and 'SSLv3' may be supported in older
    JVMs, but their usage is discouraged due to known security vulnerabilities.
    With the default value for this config and 'ssl.enabled.protocols', clients
    will downgrade to 'TLSv1.2' if the server does not support 'TLSv1.3'. If
    this config is set to 'TLSv1.2', clients will not use 'TLSv1.3' even if it
    is one of the values in ssl.enabled.protocols and the server only supports
    'TLSv1.3'.

Type: string
Default: TLSv1.3
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.provider
------------

The name of the security provider used for SSL connections. Default value is
the default security provider of the JVM.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.trustmanager.algorithm
--------------------------

The algorithm used by trust manager factory for SSL connections. Default value
is the trust manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: PKIX
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.truststore.certificates
---------------------------

Trusted certificates in the format specified by 'ssl.truststore.type'. Default
SSL engine factory supports only PEM format with X.509 certificates.

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.truststore.location
-----------------------

The location of the trust store file.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.truststore.password
-----------------------

The password for the trust store file. If a password is not set, trust store
file configured will still be used, but integrity checking is disabled. Trust
store password is not supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: per-broker


ssl.truststore.type
-------------------

The file format of the trust store file. The values currently supported by the
default `ssl.engine.factory.class` are [JKS, PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium
Update Mode: per-broker


zookeeper.clientCnxnSocket
--------------------------

Typically set to org.apache.zookeeper.ClientCnxnSocketNetty when using TLS
connectivity to ZooKeeper. Overrides any explicit value set via the same-named
zookeeper.clientCnxnSocket system property.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


zookeeper.ssl.client.enable
---------------------------

Set client to use TLS when connecting to ZooKeeper. An explicit value overrides
any value set via the zookeeper.client.secure system property (note the
different name). Defaults to false if neither is set; when true,
zookeeper.clientCnxnSocket must be set (typically to
org.apache.zookeeper.ClientCnxnSocketNetty); other values to set may include
zookeeper.ssl.cipher.suites, zookeeper.ssl.crl.enable,
zookeeper.ssl.enabled.protocols,
zookeeper.ssl.endpoint.identification.algorithm,
zookeeper.ssl.keystore.location, zookeeper.ssl.keystore.password,
zookeeper.ssl.keystore.type, zookeeper.ssl.ocsp.enable,
zookeeper.ssl.protocol, zookeeper.ssl.truststore.location,
zookeeper.ssl.truststore.password, zookeeper.ssl.truststore.type

Type: boolean
Default: false
Valid Values:
Importance: medium
Update Mode: read-only


zookeeper.ssl.keystore.location
-------------------------------

Keystore location when using a client-side certificate with TLS connectivity to
ZooKeeper. Overrides any explicit value set via the
zookeeper.ssl.keyStore.location system property (note the camelCase).

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


zookeeper.ssl.keystore.password
-------------------------------

Keystore password when using a client-side certificate with TLS connectivity to
ZooKeeper. Overrides any explicit value set via the
zookeeper.ssl.keyStore.password system property (note the camelCase). Note
that ZooKeeper does not support a key password different from the keystore
password, so be sure to set the key password in the keystore to be identical to
the keystore password; otherwise the connection attempt to Zookeeper will fail.

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


zookeeper.ssl.keystore.type
---------------------------

Keystore type when using a client-side certificate with TLS connectivity to
ZooKeeper. Overrides any explicit value set via the
zookeeper.ssl.keyStore.type system property (note the camelCase). The default
value of null means the type will be auto-detected based on the filename
extension of the keystore.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


zookeeper.ssl.truststore.location
---------------------------------

Truststore location when using TLS connectivity to ZooKeeper. Overrides any
explicit value set via the zookeeper.ssl.trustStore.location system property
(note the camelCase).

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


zookeeper.ssl.truststore.password
---------------------------------

Truststore password when using TLS connectivity to ZooKeeper. Overrides any
explicit value set via the zookeeper.ssl.trustStore.password system property
(note the camelCase).

Type: password
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


zookeeper.ssl.truststore.type
-----------------------------

Truststore type when using TLS connectivity to ZooKeeper. Overrides any
explicit value set via the zookeeper.ssl.trustStore.type system property
(note the camelCase). The default value of null means the type will be
auto-detected based on the filename extension of the truststore.

Type: string
Default: null
Valid Values:
Importance: medium
Update Mode: read-only


alter.config.policy.class.name
------------------------------

The alter configs policy class that should be used for validation. The class
should implement the org.apache.kafka.server.policy.AlterConfigPolicy
interface.

Type: class
Default: null
Valid Values:
Importance: low
Update Mode: read-only


alter.log.dirs.replication.quota.window.num
-------------------------------------------

The number of samples to retain in memory for alter log dirs replication quotas

Type: int
Default: 11
Valid Values: [1,...]
Importance: low
Update Mode: read-only


alter.log.dirs.replication.quota.window.size.seconds
----------------------------------------------------

The time span of each sample for alter log dirs replication quotas

Type: int
Default: 1
Valid Values: [1,...]
Importance: low
Update Mode: read-only


authorizer.class.name
---------------------

The fully qualified name of a class that implements
org.apache.kafka.server.authorizer.Authorizer interface, which is used by the
broker for authorization.

Type: string
Default:
Valid Values: non-null string
Importance: low
Update Mode: read-only


auto.include.jmx.reporter
-------------------------

Deprecated. Whether to automatically include JmxReporter even if it's not
listed in metric.reporters. This configuration will be removed in Kafka 4.0,
users should instead include org.apache.kafka.common.metrics.JmxReporter in
metric.reporters in order to enable the JmxReporter.

Type: boolean
Default: true
Valid Values:
Importance: low
Update Mode: read-only


client.quota.callback.class
---------------------------

The fully qualified name of a class that implements the ClientQuotaCallback
interface, which is used to determine quota limits applied to client requests.
By default, the <user> and <client-id> quotas that are stored in ZooKeeper are
applied. For any given request, the most specific quota that matches the user
principal of the session and the client-id of the request is applied.

Type: class
Default: null
Valid Values:
Importance: low
Update Mode: read-only


connection.failed.authentication.delay.ms
-----------------------------------------

Connection close delay on failed authentication: this is the time (in
milliseconds) by which connection close will be delayed on authentication
failure. This must be configured to be less than connections.max.idle.ms to
prevent connection timeout.

Type: int
Default: 100
Valid Values: [0,...]
Importance: low
Update Mode: read-only


controller.quorum.retry.backoff.ms
----------------------------------

The amount of time to wait before attempting to retry a failed request to a
given topic partition. This avoids repeatedly sending requests in a tight loop
under some failure scenarios. This value is the initial backoff value and will
increase exponentially for each failed request, up to the
retry.backoff.max.ms value.

Type: int
Default: 20
Valid Values:
Importance: low
Update Mode: read-only


controller.quota.window.num
---------------------------

The number of samples to retain in memory for controller mutation quotas

Type: int
Default: 11
Valid Values: [1,...]
Importance: low
Update Mode: read-only


controller.quota.window.size.seconds
------------------------------------

The time span of each sample for controller mutations quotas

Type: int
Default: 1
Valid Values: [1,...]
Importance: low
Update Mode: read-only


create.topic.policy.class.name
------------------------------

The create topic policy class that should be used for validation. The class
should implement the org.apache.kafka.server.policy.CreateTopicPolicy
interface.

Type: class
Default: null
Valid Values:
Importance: low
Update Mode: read-only


delegation.token.expiry.check.interval.ms
-----------------------------------------

Scan interval to remove expired delegation tokens.

Type: long
Default: 3600000 (1 hour)
Valid Values: [1,...]
Importance: low
Update Mode: read-only


kafka.metrics.polling.interval.secs
-----------------------------------

The metrics polling interval (in seconds) which can be used
inkafka.metrics.reporters implementations.

Type: int
Default: 10
Valid Values: [1,...]
Importance: low
Update Mode: read-only


kafka.metrics.reporters
-----------------------

A list of classes to use as Yammer metrics custom reporters. The reporters
should implement kafka.metrics.KafkaMetricsReporter trait. If a client wants
to expose JMX operations on a custom reporter, the custom reporter needs to
additionally implement an MBean trait that extends
kafka.metrics.KafkaMetricsReporterMBean trait so that the registered MBean is
compliant with the standard MBean convention.

Type: list
Default:
Valid Values:
Importance: low
Update Mode: read-only


listener.security.protocol.map
------------------------------

Map between listener names and security protocols. This must be defined for the
same security protocol to be usable in more than one port or IP. For example,
internal and external traffic can be separated even if SSL is required for
both. Concretely, the user could define listeners with names INTERNAL and
EXTERNAL and this property as: INTERNAL:SSL,EXTERNAL:SSL. As shown, key and
value are separated by a colon and map entries are separated by commas. Each
listener name should only appear once in the map. Different security (SSL and
SASL) settings can be configured for each listener by adding a normalised
prefix (the listener name is lowercased) to the config name. For example, to
set a different keystore for the INTERNAL listener, a config with name
listener.name.internal.ssl.keystore.location would be set. If the config for
the listener name is not set, the config will fallback to the generic config
(i.e. ssl.keystore.location). Note that in KRaft a default mapping from the
listener names defined by controller.listener.names to PLAINTEXT is assumed
if no explicit mapping is provided and no other security protocol is in use.

Type: string
Default: SASL_SSL:SASL_SSL,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT
Valid Values:
Importance: low
Update Mode: per-broker


log.dir.failure.timeout.ms
--------------------------

If the broker is unable to successfully communicate to the controller that some
log directory has failed for longer than this time, the broker will fail and
shut down.

Type: long
Default: 30000 (30 seconds)
Valid Values: [1,...]
Importance: low
Update Mode: read-only


log.message.downconversion.enable
---------------------------------

This configuration controls whether down-conversion of message formats is
enabled to satisfy consume requests. When set to false, broker will not
perform down-conversion for consumers expecting an older message format. The
broker responds with UNSUPPORTED_VERSION error for consume requests from
such older clients. This configurationdoes not apply to any message format
conversion that might be required for replication to followers.

Type: boolean
Default: true
Valid Values:
Importance: low
Update Mode: cluster-wide


metadata.max.idle.interval.ms
-----------------------------

This configuration controls how often the active controller should write no-op
records to the metadata partition. If the value is 0, no-op records are not
appended to the metadata partition. The default value is 500

Type: int
Default: 500
Valid Values: [0,...]
Importance: low
Update Mode: read-only


metric.reporters
----------------

A list of classes to use as metrics reporters. Implementing the
org.apache.kafka.common.metrics.MetricsReporter interface allows plugging in
classes that will be notified of new metric creation. The JmxReporter is always
included to register JMX statistics.

Type: list
Default:
Valid Values:
Importance: low
Update Mode: cluster-wide


metrics.num.samples
-------------------

The number of samples maintained to compute metrics.

Type: int
Default: 2
Valid Values: [1,...]
Importance: low
Update Mode: read-only


metrics.recording.level
-----------------------

The highest recording level for metrics.

Type: string
Default: INFO
Valid Values:
Importance: low
Update Mode: read-only


metrics.sample.window.ms
------------------------

The window of time a metrics sample is computed over.

Type: long
Default: 30000 (30 seconds)
Valid Values: [1,...]
Importance: low
Update Mode: read-only


password.encoder.cipher.algorithm
---------------------------------

The Cipher algorithm used for encoding dynamically configured passwords.

Type: string
Default: AES/CBC/PKCS5Padding
Valid Values:
Importance: low
Update Mode: read-only


password.encoder.iterations
---------------------------

The iteration count used for encoding dynamically configured passwords.

Type: int
Default: 4096
Valid Values: [1024,...]
Importance: low
Update Mode: read-only


password.encoder.key.length
---------------------------

The key length used for encoding dynamically configured passwords.

Type: int
Default: 128
Valid Values: [8,...]
Importance: low
Update Mode: read-only


password.encoder.keyfactory.algorithm
-------------------------------------

The SecretKeyFactory algorithm used for encoding dynamically configured
passwords. Default is PBKDF2WithHmacSHA512 if available and PBKDF2WithHmacSHA1
otherwise.

Type: string
Default: null
Valid Values:
Importance: low
Update Mode: read-only


producer.id.expiration.ms
-------------------------

The time in ms that a topic partition leader will wait before expiring producer
IDs. Producer IDs will not expire while a transaction associated to them is
still ongoing. Note that producer IDs may expire sooner if the last write from
the producer ID is deleted due to the topic's retention settings. Setting this
value the same or higher than delivery.timeout.ms can help prevent expiration
during retries and protect against message duplication, but the default should
be reasonable for most use cases.

Type: int
Default: 86400000 (1 day)
Valid Values: [1,...]
Importance: low
Update Mode: cluster-wide


quota.window.num
----------------

The number of samples to retain in memory for client quotas

Type: int
Default: 11
Valid Values: [1,...]
Importance: low
Update Mode: read-only


quota.window.size.seconds
-------------------------

The time span of each sample for client quotas

Type: int
Default: 1
Valid Values: [1,...]
Importance: low
Update Mode: read-only


remote.log.index.file.cache.total.size.bytes
--------------------------------------------

The total size of the space allocated to store index files fetched from remote
storage in the local storage.

Type: long
Default: 1073741824 (1 gibibyte)
Valid Values: [1,...]
Importance: low
Update Mode: cluster-wide


remote.log.manager.task.interval.ms
-----------------------------------

Interval at which remote log manager runs the scheduled tasks like copy
segments, and clean up remote log segments.

Type: long
Default: 30000 (30 seconds)
Valid Values: [1,...]
Importance: low
Update Mode: read-only


remote.log.metadata.custom.metadata.max.bytes
---------------------------------------------

The maximum size of custom metadata in bytes that the broker should accept from
a remote storage plugin. If custom metadata exceeds this limit, the updated
segment metadata will not be stored, the copied data will be attempted to
delete, and the remote copying task for this topic-partition will stop with an
error.

Type: int
Default: 128
Valid Values: [0,...]
Importance: low
Update Mode: read-only


replication.quota.window.num
----------------------------

The number of samples to retain in memory for replication quotas

Type: int
Default: 11
Valid Values: [1,...]
Importance: low
Update Mode: read-only


replication.quota.window.size.seconds
-------------------------------------

The time span of each sample for replication quotas

Type: int
Default: 1
Valid Values: [1,...]
Importance: low
Update Mode: read-only


sasl.login.connect.timeout.ms
-----------------------------

The (optional) value in milliseconds for the external authentication provider
connection timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low
Update Mode: read-only


sasl.login.read.timeout.ms
--------------------------

The (optional) value in milliseconds for the external authentication provider
read timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low
Update Mode: read-only


sasl.login.retry.backoff.max.ms
-------------------------------

The (optional) value in milliseconds for the maximum wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low
Update Mode: read-only


sasl.login.retry.backoff.ms
---------------------------

The (optional) value in milliseconds for the initial wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 100
Valid Values:
Importance: low
Update Mode: read-only


sasl.oauthbearer.clock.skew.seconds
-----------------------------------

The (optional) value in seconds to allow for differences between the time of
the OAuth/OIDC identity provider and the broker.

Type: int
Default: 30
Valid Values:
Importance: low
Update Mode: read-only


sasl.oauthbearer.expected.audience
----------------------------------

The (optional) comma-delimited setting for the broker to use to verify that the
JWT was issued for one of the expected audiences. The JWT will be inspected for
the standard OAuth aud claim and if this value is set, the broker will
match the value from JWT's aud claim to see if there is an exact match. If
there is no match, the broker will reject the JWT and authentication will fail.

Type: list
Default: null
Valid Values:
Importance: low
Update Mode: read-only


sasl.oauthbearer.expected.issuer
--------------------------------

The (optional) setting for the broker to use to verify that the JWT was created
by the expected issuer. The JWT will be inspected for the standard OAuth
iss claim and if this value is set, the broker will match it exactly
against what is in the JWT's iss claim. If there is no match, the broker
will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: low
Update Mode: read-only


sasl.oauthbearer.jwks.endpoint.refresh.ms
-----------------------------------------

The (optional) value in milliseconds for the broker to wait between refreshing
its JWKS (JSON Web Key Set) cache that contains the keys to verify the
signature of the JWT.

Type: long
Default: 3600000 (1 hour)
Valid Values:
Importance: low
Update Mode: read-only


sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms
---------------------------------------------------

The (optional) value in milliseconds for the maximum wait between attempts to
retrieve the JWKS (JSON Web Key Set) from the external authentication provider.
JWKS retrieval uses an exponential backoff algorithm with an initial wait based
on the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double
in wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low
Update Mode: read-only


sasl.oauthbearer.jwks.endpoint.retry.backoff.ms
-----------------------------------------------

The (optional) value in milliseconds for the initial wait between JWKS (JSON
Web Key Set) retrieval attempts from the external authentication provider. JWKS
retrieval uses an exponential backoff algorithm with an initial wait based on
the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double in
wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 100
Valid Values:
Importance: low
Update Mode: read-only


sasl.oauthbearer.scope.claim.name
---------------------------------

The OAuth claim for the scope is often named scope, but this (optional)
setting can provide a different name to use for the scope included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: scope
Valid Values:
Importance: low
Update Mode: read-only


sasl.oauthbearer.sub.claim.name
-------------------------------

The OAuth claim for the subject is often named sub, but this (optional)
setting can provide a different name to use for the subject included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: sub
Valid Values:
Importance: low
Update Mode: read-only


security.providers
------------------

A list of configurable creator classes each returning a provider implementing
security algorithms. These classes should implement the
org.apache.kafka.common.security.auth.SecurityProviderCreator interface.

Type: string
Default: null
Valid Values:
Importance: low
Update Mode: read-only


ssl.allow.dn.changes
--------------------

Indicates whether changes to the certificate distinguished name should be
allowed during a dynamic reconfiguration of certificates or not.

Type: boolean
Default: false
Valid Values:
Importance: low
Update Mode: read-only


ssl.allow.san.changes
---------------------

Indicates whether changes to the certificate subject alternative names should
be allowed during a dynamic reconfiguration of certificates or not.

Type: boolean
Default: false
Valid Values:
Importance: low
Update Mode: read-only


ssl.endpoint.identification.algorithm
-------------------------------------

The endpoint identification algorithm to validate server hostname using server
certificate.

Type: string
Default: https
Valid Values:
Importance: low
Update Mode: per-broker


ssl.engine.factory.class
------------------------

The class of type org.apache.kafka.common.security.auth.SslEngineFactory to
provide SSLEngine objects. Default value is
org.apache.kafka.common.security.ssl.DefaultSslEngineFactory. Alternatively,
setting this to
org.apache.kafka.common.security.ssl.CommonNameLoggingSslEngineFactory will log
the common name of expired SSL certificates used by clients to authenticate at
any of the brokers with log level INFO. Note that this will cause a tiny delay
during establishment of new connections from mTLS clients to brokers due to the
extra code for examining the certificate chain provided by the client. Note
further that the implementation uses a custom truststore based on the standard
Java truststore and thus might be considered a security risk due to not being
as mature as the standard one.

Type: class
Default: null
Valid Values:
Importance: low
Update Mode: per-broker


ssl.principal.mapping.rules
---------------------------

A list of rules for mapping from distinguished name from the client certificate
to short name. The rules are evaluated in order and the first rule that matches
a principal name is used to map it to a short name. Any later rules in the list
are ignored. By default, distinguished name of the X.500 certificate will be
the principal. For more details on the format please see <a
href=#security_authz> security authorization and acls</a>. Note that this
configuration is ignored if an extension of KafkaPrincipalBuilder is provided
by the principal.builder.class configuration.

Type: string
Default: DEFAULT
Valid Values:
Importance: low
Update Mode: read-only


ssl.secure.random.implementation
--------------------------------

The SecureRandom PRNG implementation to use for SSL cryptography operations.

Type: string
Default: null
Valid Values:
Importance: low
Update Mode: per-broker


telemetry.max.bytes
-------------------

The maximum size (after compression if compression is used) of telemetry
metrics pushed from a client to the broker. The default value is 1048576 (1
MB).

Type: int
Default: 1048576 (1 mebibyte)
Valid Values: [1,...]
Importance: low
Update Mode: read-only


transaction.abort.timed.out.transaction.cleanup.interval.ms
-----------------------------------------------------------

The interval at which to rollback transactions that have timed out

Type: int
Default: 10000 (10 seconds)
Valid Values: [1,...]
Importance: low
Update Mode: read-only


transaction.partition.verification.enable
-----------------------------------------

Enable verification that checks that the partition has been added to the
transaction before writing transactional records to the partition

Type: boolean
Default: true
Valid Values:
Importance: low
Update Mode: cluster-wide


transaction.remove.expired.transaction.cleanup.interval.ms
----------------------------------------------------------

The interval at which to remove transactions that have expired due to
transactional.id.expiration.ms passing

Type: int
Default: 3600000 (1 hour)
Valid Values: [1,...]
Importance: low
Update Mode: read-only


zookeeper.ssl.cipher.suites
---------------------------

Specifies the enabled cipher suites to be used in ZooKeeper TLS negotiation
(csv). Overrides any explicit value set via the zookeeper.ssl.ciphersuites
system property (note the single word ciphersuites). The default value of
null means the list of enabled cipher suites is determined by the Java
runtime being used.

Type: list
Default: null
Valid Values:
Importance: low
Update Mode: read-only


zookeeper.ssl.crl.enable
------------------------

Specifies whether to enable Certificate Revocation List in the ZooKeeper TLS
protocols. Overrides any explicit value set via the zookeeper.ssl.crl system
property (note the shorter name).

Type: boolean
Default: false
Valid Values:
Importance: low
Update Mode: read-only


zookeeper.ssl.enabled.protocols
-------------------------------

Specifies the enabled protocol(s) in ZooKeeper TLS negotiation (csv). Overrides
any explicit value set via the zookeeper.ssl.enabledProtocols system property
(note the camelCase). The default value of null means the enabled protocol
will be the value of the zookeeper.ssl.protocol configuration property.

Type: list
Default: null
Valid Values:
Importance: low
Update Mode: read-only


zookeeper.ssl.endpoint.identification.algorithm
-----------------------------------------------

Specifies whether to enable hostname verification in the ZooKeeper TLS
negotiation process, with (case-insensitively) https meaning ZooKeeper
hostname verification is enabled and an explicit blank value meaning it is
disabled (disabling it is only recommended for testing purposes). An explicit
value overrides any true or false value set via the
zookeeper.ssl.hostnameVerification system property (note the different name
and values; true implies https and false implies blank).

Type: string
Default: HTTPS
Valid Values:
Importance: low
Update Mode: read-only


zookeeper.ssl.ocsp.enable
-------------------------

Specifies whether to enable Online Certificate Status Protocol in the ZooKeeper
TLS protocols. Overrides any explicit value set via the zookeeper.ssl.ocsp
system property (note the shorter name).

Type: boolean
Default: false
Valid Values:
Importance: low
Update Mode: read-only


zookeeper.ssl.protocol
----------------------

Specifies the protocol to be used in ZooKeeper TLS negotiation. An explicit
value overrides any value set via the same-named zookeeper.ssl.protocol
system property.

Type: string
Default: TLSv1.2
Valid Values:
Importance: low
Update Mode: read-only


**TOPIC configs**

cleanup.policy
--------------

Type: list
Default: delete
Valid Values: [compact, delete]
Server Default Property: log.cleanup.policy
Importance: medium


compression.gzip.level
----------------------

The compression level to use if compression.type is set to gzip.

Type: int
Default: -1
Valid Values: [1,...,9] or -1
Server Default Property: compression.gzip.level
Importance: medium


compression.lz4.level
---------------------

The compression level to use if compression.type is set to lz4.

Type: int
Default: 9
Valid Values: [1,...,17]
Server Default Property: compression.lz4.level
Importance: medium


compression.type
----------------

Specify the final compression type for a given topic. This configuration
accepts the standard compression codecs ('gzip', 'snappy', 'lz4', 'zstd'). It
additionally accepts 'uncompressed' which is equivalent to no compression; and
'producer' which means retain the original compression codec set by the
producer.

Type: string
Default: producer
Valid Values: [uncompressed, zstd, lz4, snappy, gzip, producer]
Server Default Property: compression.type
Importance: medium


compression.zstd.level
----------------------

The compression level to use if compression.type is set to zstd.

Type: int
Default: 3
Valid Values: [-131072,...,22]
Server Default Property: compression.zstd.level
Importance: medium


delete.retention.ms
-------------------

The amount of time to retain delete tombstone markers for <a
href=#compaction>log compacted</a> topics. This setting also gives a bound
on the time in which a consumer must complete a read if they begin from offset
0 to ensure that they get a valid snapshot of the final stage (otherwise delete
tombstones may be collected before they complete their scan).

Type: long
Default: 86400000 (1 day)
Valid Values: [0,...]
Server Default Property: log.cleaner.delete.retention.ms
Importance: medium


file.delete.delay.ms
--------------------

The time to wait before deleting a file from the filesystem

Type: long
Default: 60000 (1 minute)
Valid Values: [0,...]
Server Default Property: log.segment.delete.delay.ms
Importance: medium


flush.messages
--------------

This setting allows specifying an interval at which we will force an fsync of
data written to the log. For example if this was set to 1 we would fsync after
every message; if it were 5 we would fsync after every five messages. In
general we recommend you not set this and use replication for durability and
allow the operating system's background flush capabilities as it is more
efficient. This setting can be overridden on a per-topic basis (see <a
href=#topicconfigs>the per-topic configuration section</a>).

Type: long
Default: 9223372036854775807
Valid Values: [1,...]
Server Default Property: log.flush.interval.messages
Importance: medium


flush.ms
--------

This setting allows specifying a time interval at which we will force an fsync
of data written to the log. For example if this was set to 1000 we would fsync
after 1000 ms had passed. In general we recommend you not set this and use
replication for durability and allow the operating system's background flush
capabilities as it is more efficient.

Type: long
Default: 9223372036854775807
Valid Values: [0,...]
Server Default Property: log.flush.interval.ms
Importance: medium


follower.replication.throttled.replicas
---------------------------------------

A list of replicas for which log replication should be throttled on the
follower side. The list should describe a set of replicas in the form
[PartitionId]:[BrokerId],[PartitionId]:[BrokerId]:... or alternatively
the wildcard '' can be used to throttle all replicas for this topic.

Type: list
Default:
Valid Values: [partitionId]:[brokerId],[partitionId]:[brokerId],...
Server Default Property: null
Importance: medium


index.interval.bytes
--------------------

This setting controls how frequently Kafka adds an index entry to its offset
index. The default setting ensures that we index a message roughly every 4096
bytes. More indexing allows reads to jump closer to the exact position in the
log but makes the index larger. You probably don't need to change this.

Type: int
Default: 4096 (4 kibibytes)
Valid Values: [0,...]
Server Default Property: log.index.interval.bytes
Importance: medium


leader.replication.throttled.replicas
-------------------------------------

A list of replicas for which log replication should be throttled on the leader
side. The list should describe a set of replicas in the form
[PartitionId]:[BrokerId],[PartitionId]:[BrokerId]:... or alternatively
the wildcard '' can be used to throttle all replicas for this topic.

Type: list
Default:
Valid Values: [partitionId]:[brokerId],[partitionId]:[brokerId],...
Server Default Property: null
Importance: medium


local.retention.bytes
---------------------

The maximum size of local log segments that can grow for a partition before it
deletes the old segments. Default value is -2, it represents
`retention.bytes` value to be used. The effective value should always be less
than or equal to `retention.bytes` value.

Type: long
Default: -2
Valid Values: [-2,...]
Server Default Property: log.local.retention.bytes
Importance: medium


local.retention.ms
------------------

The number of milliseconds to keep the local log segment before it gets
deleted. Default value is -2, it represents `retention.ms` value is to be
used. The effective value should always be less than or equal to
`retention.ms` value.

Type: long
Default: -2
Valid Values: [-2,...]
Server Default Property: log.local.retention.ms
Importance: medium


max.compaction.lag.ms
---------------------

The maximum time a message will remain ineligible for compaction in the log.
Only applicable for logs that are being compacted.

Type: long
Default: 9223372036854775807
Valid Values: [1,...]
Server Default Property: log.cleaner.max.compaction.lag.ms
Importance: medium


max.message.bytes
-----------------

The largest record batch size allowed by Kafka (after compression if
compression is enabled). If this is increased and there are consumers older
than 0.10.2, the consumers' fetch size must also be increased so that they can
fetch record batches this large. In the latest message format version, records
are always grouped into batches for efficiency. In previous message format
versions, uncompressed records are not grouped into batches and this limit only
applies to a single record in that case.

Type: int
Default: 1048588
Valid Values: [0,...]
Server Default Property: message.max.bytes
Importance: medium


message.format.version
----------------------

[DEPRECATED] Specify the message format version the broker will use to append
messages to the logs. The value of this config is always assumed to be `3.0`
if `inter.broker.protocol.version` is 3.0 or higher (the actual config value
    is ignored). Otherwise, the value should be a valid ApiVersion. Some
    examples are: 0.10.0, 1.1, 2.8, 3.0. By setting a particular message format
    version, the user is certifying that all the existing messages on disk are
    smaller or equal than the specified version. Setting this value incorrectly
    will cause consumers with older versions to break as they will receive
    messages with a format that they don't understand.

Type: string
Default: 3.0-IV1
Valid Values: [0.8.0, 0.8.1, 0.8.2, 0.9.0, 0.10.0-IV0, 0.10.0-IV1, 0.10.1-IV0, 0.10.1-IV1, 0.10.1-IV2, 0.10.2-IV0, 0.11.0-IV0, 0.11.0-IV1, 0.11.0-IV2, 1.0-IV0, 1.1-IV0, 2.0-IV0, 2.0-IV1, 2.1-IV0, 2.1-IV1, 2.1-IV2, 2.2-IV0, 2.2-IV1, 2.3-IV0, 2.3-IV1, 2.4-IV0, 2.4-IV1, 2.5-IV0, 2.6-IV0, 2.7-IV0, 2.7-IV1, 2.7-IV2, 2.8-IV0, 2.8-IV1, 3.0-IV0, 3.0-IV1, 3.1-IV0, 3.2-IV0, 3.3-IV0, 3.3-IV1, 3.3-IV2, 3.3-IV3, 3.4-IV0, 3.5-IV0, 3.5-IV1, 3.5-IV2, 3.6-IV0, 3.6-IV1, 3.6-IV2, 3.7-IV0, 3.7-IV1, 3.7-IV2, 3.7-IV3, 3.7-IV4, 3.8-IV0, 3.9-IV0]
Server Default Property: log.message.format.version
Importance: medium


message.timestamp.after.max.ms
------------------------------

This configuration sets the allowable timestamp difference between the message
timestamp and the broker's timestamp. The message timestamp can be later than
or equal to the broker's timestamp, with the maximum allowable difference
determined by the value set in this configuration. If
message.timestamp.type=CreateTime, the message will be rejected if the
difference in timestamps exceeds this specified threshold. This configuration
is ignored if message.timestamp.type=LogAppendTime.

Type: long
Default: 9223372036854775807
Valid Values: [0,...]
Server Default Property: log.message.timestamp.after.max.ms
Importance: medium


message.timestamp.before.max.ms
-------------------------------

This configuration sets the allowable timestamp difference between the broker's
timestamp and the message timestamp. The message timestamp can be earlier than
or equal to the broker's timestamp, with the maximum allowable difference
determined by the value set in this configuration. If
message.timestamp.type=CreateTime, the message will be rejected if the
difference in timestamps exceeds this specified threshold. This configuration
is ignored if message.timestamp.type=LogAppendTime.

Type: long
Default: 9223372036854775807
Valid Values: [0,...]
Server Default Property: log.message.timestamp.before.max.ms
Importance: medium


message.timestamp.difference.max.ms
-----------------------------------

[DEPRECATED] The maximum difference allowed between the timestamp when a
broker receives a message and the timestamp specified in the message. If
message.timestamp.type=CreateTime, a message will be rejected if the difference
in timestamp exceeds this threshold. This configuration is ignored if
message.timestamp.type=LogAppendTime.

Type: long
Default: 9223372036854775807
Valid Values: [0,...]
Server Default Property: log.message.timestamp.difference.max.ms
Importance: medium


message.timestamp.type
----------------------

Define whether the timestamp in the message is message create time or log
append time. The value should be either `CreateTime` or `LogAppendTime`

Type: string
Default: CreateTime
Valid Values: [CreateTime, LogAppendTime]
Server Default Property: log.message.timestamp.type
Importance: medium


min.cleanable.dirty.ratio
-------------------------

This configuration controls how frequently the log compactor will attempt to
clean the log (assuming <a href=#compaction>log compaction</a> is enabled).
By default we will avoid cleaning a log where more than 50% of the log has been
compacted. This ratio bounds the maximum space wasted in the log by duplicates
(at 50% at most 50% of the log could be duplicates). A higher ratio will mean
fewer, more efficient cleanings but will mean more wasted space in the log. If
the max.compaction.lag.ms or the min.compaction.lag.ms configurations are also
specified, then the log compactor considers the log to be eligible for
compaction as soon as either: (i) the dirty ratio threshold has been met and
the log has had dirty (uncompacted) records for at least the
min.compaction.lag.ms duration, or (ii) if the log has had dirty (uncompacted)
records for at most the max.compaction.lag.ms period.

Type: double
Default: 0.5
Valid Values: [0,...,1]
Server Default Property: log.cleaner.min.cleanable.ratio
Importance: medium


min.compaction.lag.ms
---------------------

The minimum time a message will remain uncompacted in the log. Only applicable
for logs that are being compacted.

Type: long
Default: 0
Valid Values: [0,...]
Server Default Property: log.cleaner.min.compaction.lag.ms
Importance: medium


min.insync.replicas
-------------------

When a producer sets acks to all (or -1), this configuration specifies
the minimum number of replicas that must acknowledge a write for the write to
be considered successful. If this minimum cannot be met, then the producer will
raise an exception (either NotEnoughReplicas or
NotEnoughReplicasAfterAppend).

When used together, min.insync.replicas and
acks allow you to enforce greater durability guarantees. A typical scenario
would be to create a topic with a replication factor of 3, set
min.insync.replicas to 2, and produce with acks of all. This will
ensure that the producer raises an exception if a majority of replicas do not
receive a write.

Type: int
Default: 1
Valid Values: [1,...]
Server Default Property: min.insync.replicas
Importance: medium


preallocate
-----------

True if we should preallocate the file on disk when creating a new log segment.

Type: boolean
Default: false
Valid Values:
Server Default Property: log.preallocate
Importance: medium


remote.storage.enable
---------------------

To enable tiered storage for a topic, set this configuration as true. You can
not disable this config once it is enabled. It will be provided in future
versions.

Type: boolean
Default: false
Valid Values:
Server Default Property: null
Importance: medium


retention.bytes
---------------

This configuration controls the maximum size a partition (which consists of log
segments) can grow to before we will discard old log segments to free up space
if we are using the delete retention policy. By default there is no size limit
only a time limit. Since this limit is enforced at the partition level,
multiply it by the number of partitions to compute the topic retention in
bytes. Additionally, retention.bytes configuration operates independently of
segment.ms and segment.bytes configurations.  Moreover, it triggers the rolling
of new segment if the retention.bytes is configured to zero.

Type: long
Default: -1
Valid Values:
Server Default Property: log.retention.bytes
Importance: medium


retention.ms
------------

This configuration controls the maximum time we will retain a log before we
will discard old log segments to free up space if we are using the delete
retention policy. This represents an SLA on how soon consumers must read their
data. If set to -1, no time limit is applied. Additionally, retention.ms
configuration operates independently of segment.ms and segment.bytes
configurations. Moreover, it triggers the rolling of new segment if the
retention.ms condition is satisfied.

Type: long
Default: 604800000 (7 days)
Valid Values: [-1,...]
Server Default Property: log.retention.ms
Importance: medium


segment.bytes
-------------

This configuration controls the segment file size for the log. Retention and
cleaning is always done a file at a time so a larger segment size means fewer
files but less granular control over retention.

Type: int
Default: 1073741824 (1 gibibyte)
Valid Values: [14,...]
Server Default Property: log.segment.bytes
Importance: medium


segment.index.bytes
-------------------

This configuration controls the size of the index that maps offsets to file
positions. We preallocate this index file and shrink it only after log rolls.
You generally should not need to change this setting.

Type: int
Default: 10485760 (10 mebibytes)
Valid Values: [4,...]
Server Default Property: log.index.size.max.bytes
Importance: medium


segment.jitter.ms
-----------------

The maximum random jitter subtracted from the scheduled segment roll time to
avoid thundering herds of segment rolling

Type: long
Default: 0
Valid Values: [0,...]
Server Default Property: log.roll.jitter.ms
Importance: medium


segment.ms
----------

This configuration controls the period of time after which Kafka will force the
log to roll even if the segment file isn't full to ensure that retention can
delete or compact old data.

Type: long
Default: 604800000 (7 days)
Valid Values: [1,...]
Server Default Property: log.roll.ms
Importance: medium


unclean.leader.election.enable
------------------------------

Indicates whether to enable replicas not in the ISR set to be elected as leader
as a last resort, even though doing so may result in data loss.

Type: boolean
Default: false
Valid Values:
Server Default Property: unclean.leader.election.enable
Importance: medium


message.downconversion.enable
-----------------------------

This configuration controls whether down-conversion of message formats is
enabled to satisfy consume requests. When set to false, broker will not
perform down-conversion for consumers expecting an older message format. The
broker responds with UNSUPPORTED_VERSION error for consume requests from
such older clients. This configurationdoes not apply to any message format
conversion that might be required for replication to followers.

Type: boolean
Default: true
Valid Values:
Server Default Property: log.message.downconversion.enable
Importance: low


key.serializer
--------------

Serializer class for key that implements the
org.apache.kafka.common.serialization.Serializer interface.

Type: class
Default:
Valid Values:
Importance: high


value.serializer
----------------

Serializer class for value that implements the
org.apache.kafka.common.serialization.Serializer interface.

Type: class
Default:
Valid Values:
Importance: high


bootstrap.servers
-----------------

A list of host/port pairs to use for establishing the initial connection to the
Kafka cluster. The client will make use of all servers irrespective of which
servers are specified here for bootstrapping&mdash;this list only impacts the
initial hosts used to discover the full set of servers. This list should be in
the form host1:port1,host2:port2,.... Since these servers are just used for
the initial connection to discover the full cluster membership (which may
change dynamically), this list need not contain the full set of servers (you
may want more than one, though, in case a server is down).

Type: list
Default:
Valid Values: non-null string
Importance: high


buffer.memory
-------------

The total bytes of memory the producer can use to buffer records waiting to be
sent to the server. If records are sent faster than they can be delivered to
the server the producer will block for max.block.ms after which it will throw
an exception.This setting should correspond roughly to the total memory the
producer will use, but is not a hard bound since not all memory the producer
uses is used for buffering. Some additional memory will be used for compression
(if compression is enabled) as well as for maintaining in-flight requests.

Type: long
Default: 33554432
Valid Values: [0,...]
Importance: high


compression.type
----------------

The compression type for all data generated by the producer. The default is
none (i.e. no compression). Valid values are none, gzip, snappy, lz4,
or zstd. Compression is of full batches of data, so the efficacy of batching
will also impact the compression ratio (more batching means better
compression).

Type: string
Default: none
Valid Values: [none, gzip, snappy, lz4, zstd]
Importance: high


retries
-------

Setting a value greater than zero will cause the client to resend any record
whose send fails with a potentially transient error. Note that this retry is no
different than if the client resent the record upon receiving the error.
Produce requests will be failed before the number of retries has been exhausted
if the timeout configured by delivery.timeout.ms expires first before
successful acknowledgement. Users should generally prefer to leave this config
unset and instead use delivery.timeout.ms to control retry behavior.Enabling
idempotence requires this config value to be greater than
0. If conflicting configurations are set and idempotence is not explicitly
enabled, idempotence is disabled.Allowing retries while setting
enable.idempotence to false and max.in.flight.requests.per.connection to
greater than 1 will potentially change the ordering of records because
if two batches are sent to a single partition, and the first fails and
is retried but the second succeeds, then the records in the second batch
may appear first.

Type: int
Default: 2147483647
Valid Values: [0,...,2147483647]
Importance: high


ssl.key.password
----------------

The password of the private key in the key store file or the PEM key specified
in 'ssl.keystore.key'.

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.certificate.chain
------------------------------

Certificate chain in the format specified by 'ssl.keystore.type'. Default SSL
engine factory supports only PEM format with a list of X.509 certificates

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.key
----------------

Private key in the format specified by 'ssl.keystore.type'. Default SSL engine
factory supports only PEM format with PKCS#8 keys. If the key is encrypted, key
password must be specified using 'ssl.key.password'

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.location
---------------------

The location of the key store file. This is optional for client and can be used
for two-way authentication for client.

Type: string
Default: null
Valid Values:
Importance: high


ssl.keystore.password
---------------------

The store password for the key store file. This is optional for client and only
needed if 'ssl.keystore.location' is configured. Key store password is not
supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: high


ssl.truststore.certificates
---------------------------

Trusted certificates in the format specified by 'ssl.truststore.type'. Default
SSL engine factory supports only PEM format with X.509 certificates.

Type: password
Default: null
Valid Values:
Importance: high


ssl.truststore.location
-----------------------

The location of the trust store file.

Type: string
Default: null
Valid Values:
Importance: high


ssl.truststore.password
-----------------------

The password for the trust store file. If a password is not set, trust store
file configured will still be used, but integrity checking is disabled. Trust
store password is not supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: high


batch.size
----------

The producer will attempt to batch records together into fewer requests
whenever multiple records are being sent to the same partition. This helps
performance on both the client and the server. This configuration controls the
default batch size in bytes. No attempt will be made to batch records larger
than this size. Requests sent to brokers will contain multiple batches, one for
each partition with data available to be sent. A small batch size will make
batching less common and may reduce throughput (a batch size of zero will
disable batching entirely). A very large batch size may use memory a bit more
wastefully as we will always allocate a buffer of the specified batch size in
anticipation of additional records.Note: This setting gives the upper bound of
the batch size to be sent. If we have fewer than this many bytes accumulated
for this partition, we will 'linger' for the linger.ms time waiting for more
records to show up. This linger.ms setting defaults to 0, which means
we'll immediately send out a record even the accumulated batch size is
under this batch.size setting.

Type: int
Default: 16384
Valid Values: [0,...]
Importance: medium


client.dns.lookup
-----------------

Controls how the client uses DNS lookups. If set to use_all_dns_ips,
connect to each returned IP address in sequence until a successful connection
is established. After a disconnection, the next IP is used. Once all IPs have
been used once, the client resolves the IP(s) from the hostname again (both the
JVM and the OS cache DNS name lookups, however). If set to
resolve_canonical_bootstrap_servers_only, resolve each bootstrap address
into a list of canonical names. After the bootstrap phase, this behaves the
same as use_all_dns_ips.

Type: string
Default: use_all_dns_ips
Valid Values: [use_all_dns_ips, resolve_canonical_bootstrap_servers_only]
Importance: medium


client.id
---------

An id string to pass to the server when making requests. The purpose of this is
to be able to track the source of requests beyond just ip/port by allowing a
logical application name to be included in server-side request logging.

Type: string
Default:
Valid Values:
Importance: medium


compression.gzip.level
----------------------

The compression level to use if compression.type is set to gzip.

Type: int
Default: -1
Valid Values: [1,...,9] or -1
Importance: medium


compression.lz4.level
---------------------

The compression level to use if compression.type is set to lz4.

Type: int
Default: 9
Valid Values: [1,...,17]
Importance: medium


compression.zstd.level
----------------------

The compression level to use if compression.type is set to zstd.

Type: int
Default: 3
Valid Values: [-131072,...,22]
Importance: medium


connections.max.idle.ms
-----------------------

Close idle connections after the number of milliseconds specified by this
config.

Type: long
Default: 540000 (9 minutes)
Valid Values:
Importance: medium


delivery.timeout.ms
-------------------

An upper bound on the time to report success or failure after a call to
send() returns. This limits the total time that a record will be delayed
prior to sending, the time to await acknowledgement from the broker (if
expected), and the time allowed for retriable send failures. The producer may
report failure to send a record earlier than this config if either an
unrecoverable error is encountered, the retries have been exhausted, or the
record is added to a batch which reached an earlier delivery expiration
deadline. The value of this config should be greater than or equal to the sum
of request.timeout.ms and linger.ms.

Type: int
Default: 120000 (2 minutes)
Valid Values: [0,...]
Importance: medium


linger.ms
---------

The producer groups together any records that arrive in between request
transmissions into a single batched request. Normally this occurs only under
load when records arrive faster than they can be sent out. However in some
circumstances the client may want to reduce the number of requests even under
moderate load. This setting accomplishes this by adding a small amount of
artificial delay&mdash;that is, rather than immediately sending out a record,
the producer will wait for up to the given delay to allow other records to be
sent so that the sends can be batched together. This can be thought of as
analogous to Nagle's algorithm in TCP. This setting gives the upper bound on
the delay for batching: once we get batch.size worth of records for a
partition it will be sent immediately regardless of this setting, however if we
have fewer than this many bytes accumulated for this partition we will 'linger'
for the specified time waiting for more records to show up. This setting
defaults to 0 (i.e. no delay). Setting linger.ms=5, for example, would
have the effect of reducing the number of requests sent but would add up to
5ms of latency to records sent in the absence of load.

Type: long
Default: 0
Valid Values: [0,...]
Importance: medium


max.block.ms
------------

The configuration controls how long the KafkaProducer's send(),
partitionsFor(), initTransactions(), sendOffsetsToTransaction(),
commitTransaction() and abortTransaction() methods will block. For send()
this timeout bounds the total time waiting for both metadata fetch and buffer
allocation (blocking in the user-supplied serializers or partitioner is not
counted against this timeout). For partitionsFor() this timeout bounds the
time spent waiting for metadata if it is unavailable. The transaction-related
methods always block, but may timeout if the transaction coordinator could not
be discovered or did not respond within the timeout.

Type: long
Default: 60000 (1 minute)
Valid Values: [0,...]
Importance: medium


max.request.size
----------------

The maximum size of a request in bytes. This setting will limit the number of
record batches the producer will send in a single request to avoid sending huge
requests. This is also effectively a cap on the maximum uncompressed record
batch size. Note that the server has its own cap on the record batch size
(after compression if compression is enabled) which may be different from this.

Type: int
Default: 1048576
Valid Values: [0,...]
Importance: medium


partitioner.class
-----------------

Determines which partition to send a record to when records are produced.
Available options are:<ul><li>If not set, the default partitioning logic is
used. This strategy send records to a partition until at least batch.size bytes
is produced to the partition. It works with the strategy:<ol><li>If no
partition is specified but a key is present, choose a partition based on a hash
of the key.</li><li>If no partition or key is present, choose the sticky
partition that changes when at least batch.size bytes are produced to the
partition.</li></ol></li><li>org.apache.kafka.clients.producer.RoundRobinPartitioner:
A partitioning strategy where each record in a series of consecutive records is
sent to a different partition, regardless of whether the 'key' is provided or
not, until partitions run out and the process starts over again. Note: There's
a known issue that will cause uneven distribution when a new batch is created.
See KAFKA-9965 for more detail.</li></ul>Implementing the
org.apache.kafka.clients.producer.Partitioner interface allows you to plug in
a custom partitioner.

Type: class
Default: null
Valid Values:
Importance: medium


partitioner.ignore.keys
-----------------------

When set to 'true' the producer won't use record keys to choose a partition. If
'false', producer would choose a partition based on a hash of the key when a
key is present. Note: this setting has no effect if a custom partitioner is
used.

Type: boolean
Default: false
Valid Values:
Importance: medium


receive.buffer.bytes
--------------------

The size of the TCP receive buffer (SO_RCVBUF) to use when reading data. If
the value is -1, the OS default will be used.

Type: int
Default: 32768 (32 kibibytes)
Valid Values: [-1,...]
Importance: medium


request.timeout.ms
------------------

The configuration controls the maximum amount of time the client will wait for
the response of a request. If the response is not received before the timeout
elapses the client will resend the request if necessary or fail the request if
retries are exhausted. This should be larger than replica.lag.time.max.ms (a
broker configuration) to reduce the possibility of message duplication due to
unnecessary producer retries.

Type: int
Default: 30000 (30 seconds)
Valid Values: [0,...]
Importance: medium


sasl.client.callback.handler.class
----------------------------------

The fully qualified name of a SASL client callback handler class that
implements the AuthenticateCallbackHandler interface.

Type: class
Default: null
Valid Values:
Importance: medium


sasl.jaas.config
----------------

JAAS login context parameters for SASL connections in the format used by JAAS
configuration files. JAAS configuration file format is described <a
href=https://docs.oracle.com/javase/8/docs/technotes/guides/security/jgss/tutorials/LoginConfigFile.html>here</a>.
The format for the value is: loginModuleClass controlFlag
(optionName=optionValue);. For brokers, the config must be prefixed with
listener prefix and SASL mechanism name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.jaas.config=com.example.ScramLoginModule
required;

Type: password
Default: null
Valid Values:
Importance: medium


sasl.kerberos.service.name
--------------------------

The Kerberos principal name that Kafka runs as. This can be defined either in
Kafka's JAAS config or in Kafka's config.

Type: string
Default: null
Valid Values:
Importance: medium


sasl.login.callback.handler.class
---------------------------------

The fully qualified name of a SASL login callback handler class that implements
the AuthenticateCallbackHandler interface. For brokers, login callback handler
config must be prefixed with listener prefix and SASL mechanism name in
lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.callback.handler.class=com.example.CustomScramLoginCallbackHandler

Type: class
Default: null
Valid Values:
Importance: medium


sasl.login.class
----------------

The fully qualified name of a class that implements the Login interface. For
brokers, login config must be prefixed with listener prefix and SASL mechanism
name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.class=com.example.CustomScramLogin

Type: class
Default: null
Valid Values:
Importance: medium


sasl.mechanism
--------------

SASL mechanism used for client connections. This may be any mechanism for which
a security provider is available. GSSAPI is the default mechanism.

Type: string
Default: GSSAPI
Valid Values:
Importance: medium


sasl.oauthbearer.jwks.endpoint.url
----------------------------------

The OAuth/OIDC provider URL from which the provider's <a
href=https://datatracker.ietf.org/doc/html/rfc7517#section-5>JWKS (JSON Web
Key Set)</a> can be retrieved. The URL can be HTTP(S)-based or file-based. If
the URL is HTTP(S)-based, the JWKS data will be retrieved from the OAuth/OIDC
provider via the configured URL on broker startup. All then-current keys will
be cached on the broker for incoming requests. If an authentication request is
received for a JWT that includes a kid header claim value that isn't yet in
the cache, the JWKS endpoint will be queried again on demand. However, the
broker polls the URL every sasl.oauthbearer.jwks.endpoint.refresh.ms
milliseconds to refresh the cache with any forthcoming keys before any JWT
requests that include them are received. If the URL is file-based, the broker
will load the JWKS file from a configured location on startup. In the event
that the JWT includes a kid header value that isn't in the JWKS file, the
broker will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: medium


sasl.oauthbearer.token.endpoint.url
-----------------------------------

The URL for the OAuth/OIDC identity provider. If the URL is HTTP(S)-based, it
is the issuer's token endpoint URL to which requests will be made to login
based on the configuration in sasl.jaas.config. If the URL is file-based, it
specifies a file containing an access token (in JWT serialized form) issued by
the OAuth/OIDC identity provider to use for authorization.

Type: string
Default: null
Valid Values:
Importance: medium


security.protocol
-----------------

Protocol used to communicate with brokers. Valid values are: PLAINTEXT, SSL,
SASL_PLAINTEXT, SASL_SSL.

Type: string
Default: PLAINTEXT
Valid Values: (case insensitive) [SASL_SSL, PLAINTEXT, SSL, SASL_PLAINTEXT]
Importance: medium


send.buffer.bytes
-----------------

The size of the TCP send buffer (SO_SNDBUF) to use when sending data. If the
value is -1, the OS default will be used.

Type: int
Default: 131072 (128 kibibytes)
Valid Values: [-1,...]
Importance: medium


socket.connection.setup.timeout.max.ms
--------------------------------------

The maximum amount of time the client will wait for the socket connection to be
established. The connection setup timeout will increase exponentially for each
consecutive connection failure up to this maximum. To avoid connection storms,
a randomization factor of 0.2 will be applied to the timeout resulting in a
random range between 20% below and 20% above the computed value.

Type: long
Default: 30000 (30 seconds)
Valid Values:
Importance: medium


socket.connection.setup.timeout.ms
----------------------------------

The amount of time the client will wait for the socket connection to be
established. If the connection is not built before the timeout elapses, clients
will close the socket channel. This value is the initial backoff value and will
increase exponentially for each consecutive connection failure, up to the
socket.connection.setup.timeout.max.ms value.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: medium


ssl.enabled.protocols
---------------------

The list of protocols enabled for SSL connections. The default is
'TLSv1.2,TLSv1.3' when running with Java 11 or newer, 'TLSv1.2' otherwise. With
the default value for Java 11, clients and servers will prefer TLSv1.3 if both
support it and fallback to TLSv1.2 otherwise (assuming both support at least
TLSv1.2). This default should be fine for most cases. Also see the config
documentation for `ssl.protocol`.

Type: list
Default: TLSv1.2,TLSv1.3
Valid Values:
Importance: medium


ssl.keystore.type
-----------------

The file format of the key store file. This is optional for client. The values
currently supported by the default `ssl.engine.factory.class` are [JKS,
PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium


ssl.protocol
------------

The SSL protocol used to generate the SSLContext. The default is 'TLSv1.3' when
running with Java 11 or newer, 'TLSv1.2' otherwise. This value should be fine
for most use cases. Allowed values in recent JVMs are 'TLSv1.2' and 'TLSv1.3'.
'TLS', 'TLSv1.1', 'SSL', 'SSLv2' and 'SSLv3' may be supported in older
JVMs, but their usage is discouraged due to known security vulnerabilities.
With the default value for this config and 'ssl.enabled.protocols', clients
will downgrade to 'TLSv1.2' if the server does not support 'TLSv1.3'. If
this config is set to 'TLSv1.2', clients will not use 'TLSv1.3' even if it
is one of the values in ssl.enabled.protocols and the server only supports
'TLSv1.3'.

Type: string
Default: TLSv1.3
Valid Values:
Importance: medium


ssl.provider
------------

The name of the security provider used for SSL connections. Default value is
the default security provider of the JVM.

Type: string
Default: null
Valid Values:
Importance: medium


ssl.truststore.type
-------------------

The file format of the trust store file. The values currently supported by the
default `ssl.engine.factory.class` are [JKS, PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium


acks
----

The number of acknowledgments the producer requires the leader to have received
before considering a request complete. This controls the durability of records
that are sent. The following settings are allowed:

`acks=0`:

If set to zero then the producer will not wait for any acknowledgment from the
server at all. The record will be immediately added to the socket buffer and
considered sent. No guarantee can be made that the server has received the
record in this case, and the retries configuration will not take effect (as the
client won't generally know of any failures). The offset given back for each
record will always be set to -1.

`acks=1`:

This will mean the leader will write the record to its local log but will
respond without awaiting full acknowledgement from all followers. In this case
should the leader fail immediately after acknowledging the record but before
the followers have replicated it then the record will be lost.


`acks=all`:

This means the leader will wait for the full set of in-sync replicas to
acknowledge the record. This guarantees that the record will not be lost as
long as at least one in-sync replica remains alive. This is the strongest
available guarantee. This is equivalent to the acks=-1 setting. Note that
enabling idempotence requires this config value to be 'all'. If conflicting
configurations are set and idempotence is not explicitly enabled, idempotence
is disabled.

Type: string
Default: all
Valid Values: [all, -1, 0, 1]
Importance: low


auto.include.jmx.reporter
-------------------------

Deprecated. Whether to automatically include JmxReporter even if it's not
listed in metric.reporters. This configuration will be removed in Kafka 4.0,
users should instead include org.apache.kafka.common.metrics.JmxReporter in
metric.reporters in order to enable the JmxReporter.

Type: boolean
Default: true
Valid Values:
Importance: low


enable.idempotence
------------------

When set to 'true', the producer will ensure that exactly one copy of each
message is written in the stream. If 'false', producer retries due to broker
failures, etc., may write duplicates of the retried message in the stream. Note
that enabling idempotence requires max.in.flight.requests.per.connection to
be less than or equal to 5 (with message ordering preserved for any allowable
value), retries to be greater than 0, and acks must be 'all'. Idempotence
is enabled by default if no conflicting configurations are set. If conflicting
configurations are set and idempotence is not explicitly enabled, idempotence
is disabled. If idempotence is explicitly enabled and conflicting
configurations are set, a ConfigException is thrown.

Type: boolean
Default: true
Valid Values:
Importance: low


enable.metrics.push
-------------------

Whether to enable pushing of client metrics to the cluster, if the cluster has
a client metrics subscription which matches this client.

Type: boolean
Default: true
Valid Values:
Importance: low


interceptor.classes
-------------------

A list of classes to use as interceptors. Implementing the
org.apache.kafka.clients.producer.ProducerInterceptor interface allows you to
intercept (and possibly mutate) the records received by the producer before
they are published to the Kafka cluster. By default, there are no interceptors.

Type: list
Default:
Valid Values: non-null string
Importance: low


max.in.flight.requests.per.connection
-------------------------------------

The maximum number of unacknowledged requests the client will send on a single
connection before blocking. Note that if this configuration is set to be
greater than 1 and enable.idempotence is set to false, there is a risk of
message reordering after a failed send due to retries (i.e., if retries are
enabled); if retries are disabled or if enable.idempotence is set to true,
ordering will be preserved. Additionally, enabling idempotence requires the
value of this configuration to be less than or equal to 5. If conflicting
configurations are set and idempotence is not explicitly enabled, idempotence
is disabled.

Type: int
Default: 5
Valid Values: [1,...]
Importance: low


metadata.max.age.ms
-------------------

The period of time in milliseconds after which we force a refresh of metadata
even if we haven't seen any partition leadership changes to proactively
discover any new brokers or partitions.

Type: long
Default: 300000 (5 minutes)
Valid Values: [0,...]
Importance: low


metadata.max.idle.ms
--------------------

Controls how long the producer will cache metadata for a topic that's idle. If
the elapsed time since a topic was last produced to exceeds the metadata idle
duration, then the topic's metadata is forgotten and the next access to it will
force a metadata fetch request.

Type: long
Default: 300000 (5 minutes)
Valid Values: [5000,...]
Importance: low


metadata.recovery.strategy
--------------------------

Controls how the client recovers when none of the brokers known to it is
available. If set to none, the client fails. If set to rebootstrap, the
client repeats the bootstrap process using bootstrap.servers. Rebootstrapping
is useful when a client communicates with brokers so infrequently that the set
of brokers may change entirely before the client refreshes metadata. Metadata
recovery is triggered when all last-known brokers appear unavailable
simultaneously. Brokers appear unavailable when disconnected and no current
retry attempt is in-progress. Consider increasing reconnect.backoff.ms and
reconnect.backoff.max.ms and decreasing socket.connection.setup.timeout.ms
and socket.connection.setup.timeout.max.ms for the client.

Type: string
Default: none
Valid Values: (case insensitive) [REBOOTSTRAP, NONE]
Importance: low


metric.reporters
----------------

A list of classes to use as metrics reporters. Implementing the
org.apache.kafka.common.metrics.MetricsReporter interface allows plugging in
classes that will be notified of new metric creation. The JmxReporter is always
included to register JMX statistics.

Type: list
Default:
Valid Values: non-null string
Importance: low


metrics.num.samples
-------------------

The number of samples maintained to compute metrics.

Type: int
Default: 2
Valid Values: [1,...]
Importance: low


metrics.recording.level
-----------------------

The highest recording level for metrics.

Type: string
Default: INFO
Valid Values: [INFO, DEBUG, TRACE]
Importance: low


metrics.sample.window.ms
------------------------

The window of time a metrics sample is computed over.

Type: long
Default: 30000 (30 seconds)
Valid Values: [0,...]
Importance: low


partitioner.adaptive.partitioning.enable
----------------------------------------

When set to 'true', the producer will try to adapt to broker performance and
produce more messages to partitions hosted on faster brokers. If 'false',
producer will try to distribute messages uniformly. Note: this setting has no
effect if a custom partitioner is used

Type: boolean
Default: true
Valid Values:
Importance: low


partitioner.availability.timeout.ms
-----------------------------------

If a broker cannot process produce requests from a partition for
partitioner.availability.timeout.ms time, the partitioner treats that
partition as not available. If the value is 0, this logic is disabled. Note:
this setting has no effect if a custom partitioner is used or
partitioner.adaptive.partitioning.enable is set to 'false'

Type: long
Default: 0
Valid Values: [0,...]
Importance: low


reconnect.backoff.max.ms
------------------------

The maximum amount of time in milliseconds to wait when reconnecting to a
broker that has repeatedly failed to connect. If provided, the backoff per host
will increase exponentially for each consecutive connection failure, up to this
maximum. After calculating the backoff increase, 20% random jitter is added to
avoid connection storms.

Type: long
Default: 1000 (1 second)
Valid Values: [0,...]
Importance: low


reconnect.backoff.ms
--------------------

The base amount of time to wait before attempting to reconnect to a given host.
This avoids repeatedly connecting to a host in a tight loop. This backoff
applies to all connection attempts by the client to a broker. This value is the
initial backoff value and will increase exponentially for each consecutive
connection failure, up to the reconnect.backoff.max.ms value.

Type: long
Default: 50
Valid Values: [0,...]
Importance: low


retry.backoff.max.ms
--------------------

The maximum amount of time in milliseconds to wait when retrying a request to
the broker that has repeatedly failed. If provided, the backoff per client will
increase exponentially for each failed request, up to this maximum. To prevent
all clients from being synchronized upon retry, a randomized jitter with a
factor of 0.2 will be applied to the backoff, resulting in the backoff falling
within a range between 20% below and 20% above the computed value. If
retry.backoff.ms is set to be higher than retry.backoff.max.ms, then
retry.backoff.max.ms will be used as a constant backoff from the beginning
without any exponential increase

Type: long
Default: 1000 (1 second)
Valid Values: [0,...]
Importance: low


retry.backoff.ms
----------------

The amount of time to wait before attempting to retry a failed request to a
given topic partition. This avoids repeatedly sending requests in a tight loop
under some failure scenarios. This value is the initial backoff value and will
increase exponentially for each failed request, up to the
retry.backoff.max.ms value.

Type: long
Default: 100
Valid Values: [0,...]
Importance: low


sasl.kerberos.kinit.cmd
-----------------------

Kerberos kinit command path.

Type: string
Default: /usr/bin/kinit
Valid Values:
Importance: low


sasl.kerberos.min.time.before.relogin
-------------------------------------

Login thread sleep time between refresh attempts.

Type: long
Default: 60000
Valid Values:
Importance: low


sasl.kerberos.ticket.renew.jitter
---------------------------------

Percentage of random jitter added to the renewal time.

Type: double
Default: 0.05
Valid Values:
Importance: low


sasl.kerberos.ticket.renew.window.factor
----------------------------------------

Login thread will sleep until the specified window factor of time from last
refresh to ticket's expiry has been reached, at which time it will try to renew
the ticket.

Type: double
Default: 0.8
Valid Values:
Importance: low


sasl.login.connect.timeout.ms
-----------------------------

The (optional) value in milliseconds for the external authentication provider
connection timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low


sasl.login.read.timeout.ms
--------------------------

The (optional) value in milliseconds for the external authentication provider
read timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low


sasl.login.refresh.buffer.seconds
---------------------------------

The amount of buffer time before credential expiration to maintain when
refreshing a credential, in seconds. If a refresh would otherwise occur closer
to expiration than the number of buffer seconds then the refresh will be moved
up to maintain as much of the buffer time as possible. Legal values are between
0 and 3600 (1 hour); a default value of 300 (5 minutes) is used if no value is
specified. This value and sasl.login.refresh.min.period.seconds are both
ignored if their sum exceeds the remaining lifetime of a credential. Currently
applies only to OAUTHBEARER.

Type: short
Default: 300
Valid Values: [0,...,3600]
Importance: low


sasl.login.refresh.min.period.seconds
-------------------------------------

The desired minimum time for the login refresh thread to wait before refreshing
a credential, in seconds. Legal values are between 0 and 900 (15 minutes); a
default value of 60 (1 minute) is used if no value is specified. This value and
sasl.login.refresh.buffer.seconds are both ignored if their sum exceeds the
remaining lifetime of a credential. Currently applies only to OAUTHBEARER.

Type: short
Default: 60
Valid Values: [0,...,900]
Importance: low


sasl.login.refresh.window.factor
--------------------------------

Login refresh thread will sleep until the specified window factor relative to
the credential's lifetime has been reached, at which time it will try to
refresh the credential. Legal values are between 0.5 (50%) and 1.0 (100%)
inclusive; a default value of 0.8 (80%) is used if no value is specified.
Currently applies only to OAUTHBEARER.

Type: double
Default: 0.8
Valid Values: [0.5,...,1.0]
Importance: low


sasl.login.refresh.window.jitter
--------------------------------

The maximum amount of random jitter relative to the credential's lifetime that
is added to the login refresh thread's sleep time. Legal values are between 0
and 0.25 (25%) inclusive; a default value of 0.05 (5%) is used if no value is
specified. Currently applies only to OAUTHBEARER.

Type: double
Default: 0.05
Valid Values: [0.0,...,0.25]
Importance: low


sasl.login.retry.backoff.max.ms
-------------------------------

The (optional) value in milliseconds for the maximum wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low


sasl.login.retry.backoff.ms
---------------------------

The (optional) value in milliseconds for the initial wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 100
Valid Values:
Importance: low


sasl.oauthbearer.clock.skew.seconds
-----------------------------------

The (optional) value in seconds to allow for differences between the time of
the OAuth/OIDC identity provider and the broker.

Type: int
Default: 30
Valid Values:
Importance: low


sasl.oauthbearer.expected.audience
----------------------------------

The (optional) comma-delimited setting for the broker to use to verify that the
JWT was issued for one of the expected audiences. The JWT will be inspected for
the standard OAuth aud claim and if this value is set, the broker will
match the value from JWT's aud claim to see if there is an exact match. If
there is no match, the broker will reject the JWT and authentication will fail.

Type: list
Default: null
Valid Values:
Importance: low


sasl.oauthbearer.expected.issuer
--------------------------------

The (optional) setting for the broker to use to verify that the JWT was created
by the expected issuer. The JWT will be inspected for the standard OAuth
iss claim and if this value is set, the broker will match it exactly
against what is in the JWT's iss claim. If there is no match, the broker
will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.refresh.ms
-----------------------------------------

The (optional) value in milliseconds for the broker to wait between refreshing
its JWKS (JSON Web Key Set) cache that contains the keys to verify the
signature of the JWT.

Type: long
Default: 3600000 (1 hour)
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms
---------------------------------------------------

The (optional) value in milliseconds for the maximum wait between attempts to
retrieve the JWKS (JSON Web Key Set) from the external authentication provider.
JWKS retrieval uses an exponential backoff algorithm with an initial wait based
on the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double
in wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.retry.backoff.ms
-----------------------------------------------

The (optional) value in milliseconds for the initial wait between JWKS (JSON
Web Key Set) retrieval attempts from the external authentication provider. JWKS
retrieval uses an exponential backoff algorithm with an initial wait based on
the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double in
wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 100
Valid Values:
Importance: low


sasl.oauthbearer.scope.claim.name
---------------------------------

The OAuth claim for the scope is often named scope, but this (optional)
setting can provide a different name to use for the scope included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: scope
Valid Values:
Importance: low


sasl.oauthbearer.sub.claim.name
-------------------------------

The OAuth claim for the subject is often named sub, but this (optional)
setting can provide a different name to use for the subject included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: sub
Valid Values:
Importance: low


security.providers
------------------

A list of configurable creator classes each returning a provider implementing
security algorithms. These classes should implement the
org.apache.kafka.common.security.auth.SecurityProviderCreator interface.

Type: string
Default: null
Valid Values:
Importance: low


ssl.cipher.suites
-----------------

A list of cipher suites. This is a named combination of authentication,
encryption, MAC and key exchange algorithm used to negotiate the security
settings for a network connection using TLS or SSL network protocol. By default
all the available cipher suites are supported.

Type: list
Default: null
Valid Values:
Importance: low


ssl.endpoint.identification.algorithm
-------------------------------------

The endpoint identification algorithm to validate server hostname using server
certificate.

Type: string
Default: https
Valid Values:
Importance: low


ssl.engine.factory.class
------------------------

The class of type org.apache.kafka.common.security.auth.SslEngineFactory to
provide SSLEngine objects. Default value is
org.apache.kafka.common.security.ssl.DefaultSslEngineFactory. Alternatively,
setting this to
org.apache.kafka.common.security.ssl.CommonNameLoggingSslEngineFactory will log
the common name of expired SSL certificates used by clients to authenticate at
any of the brokers with log level INFO. Note that this will cause a tiny delay
during establishment of new connections from mTLS clients to brokers due to the
extra code for examining the certificate chain provided by the client. Note
further that the implementation uses a custom truststore based on the standard
Java truststore and thus might be considered a security risk due to not being
as mature as the standard one.

Type: class
Default: null
Valid Values:
Importance: low


ssl.keymanager.algorithm
------------------------

The algorithm used by key manager factory for SSL connections. Default value is
the key manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: SunX509
Valid Values:
Importance: low


ssl.secure.random.implementation
--------------------------------

The SecureRandom PRNG implementation to use for SSL cryptography operations.

Type: string
Default: null
Valid Values:
Importance: low


ssl.trustmanager.algorithm
--------------------------

The algorithm used by trust manager factory for SSL connections. Default value
is the trust manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: PKIX
Valid Values:
Importance: low


transaction.timeout.ms
----------------------

The maximum amount of time in milliseconds that a transaction will remain open
before the coordinator proactively aborts it. The start of the transaction is
set at the time that the first partition is added to it. If this value is
larger than the transaction.max.timeout.ms setting in the broker, the request
will fail with a InvalidTxnTimeoutException error.

Type: int
Default: 60000 (1 minute)
Valid Values:
Importance: low


transactional.id
----------------

The TransactionalId to use for transactional delivery. This enables reliability
semantics which span multiple producer sessions since it allows the client to
guarantee that transactions using the same TransactionalId have been completed
prior to starting any new transactions. If no TransactionalId is provided, then
the producer is limited to idempotent delivery. If a TransactionalId is
configured, enable.idempotence is implied. By default the TransactionId is
not configured, which means transactions cannot be used. Note that, by default,
transactions require a cluster of at least three brokers which is the
recommended setting for production; for development you can change this, by
adjusting broker setting transaction.state.log.replication.factor.

Type: string
Default: null
Valid Values: non-empty string
Importance: low


value.deserializer
------------------

Deserializer class for value that implements the
org.apache.kafka.common.serialization.Deserializer interface.

Type: class
Default:
Valid Values:
Importance: high


bootstrap.servers
-----------------

A list of host/port pairs to use for establishing the initial connection to the
Kafka cluster. The client will make use of all servers irrespective of which
servers are specified here for bootstrapping - this list only impacts the
initial hosts used to discover the full set of servers. This list should be in
the form host1:port1,host2:port2,.... Since these servers are just used for
the initial connection to discover the full cluster membership (which may
change dynamically), this list need not contain the full set of servers (you
may want more than one, though, in case a server is down).

Type: list
Default:
Valid Values: non-null string
Importance: high


fetch.min.bytes
---------------

The minimum amount of data the server should return for a fetch request. If
insufficient data is available the request will wait for that much data to
accumulate before answering the request. The default setting of 1 byte means
that fetch requests are answered as soon as that many byte(s) of data is
available or the fetch request times out waiting for data to arrive. Setting
this to a larger value will cause the server to wait for larger amounts of data
to accumulate which can improve server throughput a bit at the cost of some
additional latency.

Type: int
Default: 1
Valid Values: [0,...]
Importance: high


group.id
--------

A unique string that identifies the consumer group this consumer belongs to.
This property is required if the consumer uses either the group management
functionality by using subscribe(topic) or the Kafka-based offset management
strategy.

Type: string
Default: null
Valid Values:
Importance: high


group.protocol
--------------

The group protocol consumer should use. We currently support classic or
consumer. If consumer is specified, then the consumer group protocol
will be used. Otherwise, the classic group protocol will be used.

Type: string
Default: classic
Valid Values: (case insensitive) [CONSUMER, CLASSIC]
Importance: high


heartbeat.interval.ms
---------------------

The expected time between heartbeats to the consumer coordinator when using
Kafka's group management facilities. Heartbeats are used to ensure that the
consumer's session stays active and to facilitate rebalancing when new
consumers join or leave the group. The value must be set lower than
session.timeout.ms, but typically should be set no higher than 1/3 of that
value. It can be adjusted even lower to control the expected time for normal
rebalances.

Type: int
Default: 3000 (3 seconds)
Valid Values:
Importance: high


max.partition.fetch.bytes
-------------------------

The maximum amount of data per-partition the server will return. Records are
fetched in batches by the consumer. If the first record batch in the first
non-empty partition of the fetch is larger than this limit, the batch will
still be returned to ensure that the consumer can make progress. The maximum
record batch size accepted by the broker is defined via message.max.bytes
(broker config) or max.message.bytes (topic config). See fetch.max.bytes for
limiting the consumer request size.

Type: int
Default: 1048576 (1 mebibyte)
Valid Values: [0,...]
Importance: high


session.timeout.ms
------------------

The timeout used to detect client failures when using Kafka's group management
facility. The client sends periodic heartbeats to indicate its liveness to the
broker. If no heartbeats are received by the broker before the expiration of
this session timeout, then the broker will remove this client from the group
and initiate a rebalance. Note that the value must be in the allowable range as
configured in the broker configuration by group.min.session.timeout.ms and
group.max.session.timeout.ms.

Type: int
Default: 45000 (45 seconds)
Valid Values:
Importance: high


ssl.key.password
----------------

The password of the private key in the key store file or the PEM key specified
in 'ssl.keystore.key'.

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.certificate.chain
------------------------------

Certificate chain in the format specified by 'ssl.keystore.type'. Default SSL
engine factory supports only PEM format with a list of X.509 certificates

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.key
----------------

Private key in the format specified by 'ssl.keystore.type'. Default SSL engine
factory supports only PEM format with PKCS#8 keys. If the key is encrypted, key
password must be specified using 'ssl.key.password'

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.location
---------------------

The location of the key store file. This is optional for client and can be used
for two-way authentication for client.

Type: string
Default: null
Valid Values:
Importance: high


ssl.keystore.password
---------------------

The store password for the key store file. This is optional for client and only
needed if 'ssl.keystore.location' is configured. Key store password is not
supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: high


ssl.truststore.certificates
---------------------------

Trusted certificates in the format specified by 'ssl.truststore.type'. Default
SSL engine factory supports only PEM format with X.509 certificates.

Type: password
Default: null
Valid Values:
Importance: high


ssl.truststore.location
-----------------------

The location of the trust store file.

Type: string
Default: null
Valid Values:
Importance: high


ssl.truststore.password
-----------------------

The password for the trust store file. If a password is not set, trust store
file configured will still be used, but integrity checking is disabled. Trust
store password is not supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: high


allow.auto.create.topics
------------------------

Allow automatic topic creation on the broker when subscribing to or assigning a
topic. A topic being subscribed to will be automatically created only if the
broker allows for it using `auto.create.topics.enable` broker configuration.
This configuration must be set to `false` when using brokers older than
0.11.0

Type: boolean
Default: true
Valid Values:
Importance: medium


auto.offset.reset
-----------------

What to do when there is no initial offset in Kafka or if the current offset
does not exist any more on the server (e.g. because that data has been
deleted):

earliest: automatically reset the offset to the earliest offset

latest: automatically reset the offset to the latest offset

none: throw exception to the consumer if no previous offset is found for the
consumer's group

anything else: throw exception to the consumer.

Note that altering partition numbers while setting this config to latest may
cause message delivery loss since producers could start to send messages to
newly added partitions (i.e. no initial offsets exist yet) before consumers
reset their offsets.

Type: string
Default: latest
Valid Values: [latest, earliest, none]
Importance: medium


client.dns.lookup
-----------------

Controls how the client uses DNS lookups. If set to use_all_dns_ips, connect to
each returned IP address in sequence until a successful connection is
established. After a disconnection, the next IP is used. Once all IPs have been
used once, the client resolves the IP(s) from the hostname again (both the JVM
and the OS cache DNS name lookups, however). If set to
resolve_canonical_bootstrap_servers_only, resolve each bootstrap address into a
list of canonical names. After the bootstrap phase, this behaves the same as
use_all_dns_ips.

Type: string
Default: use_all_dns_ips
Valid Values: [use_all_dns_ips, resolve_canonical_bootstrap_servers_only]
Importance: medium


connections.max.idle.ms
-----------------------

Close idle connections after the number of milliseconds specified by this
config.

Type: long
Default: 540000 (9 minutes)
Valid Values:
Importance: medium


default.api.timeout.ms
----------------------

Specifies the timeout (in milliseconds) for client APIs. This configuration is
used as the default timeout for all client operations that do not specify a
timeout parameter.

Type: int
Default: 60000 (1 minute)
Valid Values: [0,...]
Importance: medium


enable.auto.commit
------------------

If true the consumer's offset will be periodically committed in the background.

Type: boolean
Default: true
Valid Values:
Importance: medium


exclude.internal.topics
-----------------------

Whether internal topics matching a subscribed pattern should be excluded from
the subscription. It is always possible to explicitly subscribe to an internal
topic.

Type: boolean
Default: true
Valid Values:
Importance: medium


fetch.max.bytes
---------------

The maximum amount of data the server should return for a fetch request.
Records are fetched in batches by the consumer, and if the first record batch
in the first non-empty partition of the fetch is larger than this value, the
record batch will still be returned to ensure that the consumer can make
progress. As such, this is not a absolute maximum. The maximum record batch
size accepted by the broker is defined via message.max.bytes (broker config)
or max.message.bytes (topic config). Note that the consumer performs multiple
fetches in parallel.

Type: int
Default: 52428800 (50 mebibytes)
Valid Values: [0,...]
Importance: medium


group.instance.id
-----------------

A unique identifier of the consumer instance provided by the end user. Only
non-empty strings are permitted. If set, the consumer is treated as a static
member, which means that only one instance with this ID is allowed in the
consumer group at any time. This can be used in combination with a larger
session timeout to avoid group rebalances caused by transient unavailability
(e.g. process restarts). If not set, the consumer will join the group as a
dynamic member, which is the traditional behavior.

Type: string
Default: null
Valid Values: non-empty string
Importance: medium


group.remote.assignor
---------------------

The server-side assignor to use. If no assignor is specified, the group
coordinator will pick one. This configuration is applied only if
group.protocol is set to consumer.

Type: string
Default: null
Valid Values:
Importance: medium


isolation.level
---------------

Controls how to read messages written transactionally. If set to
read_committed, consumer.poll() will only return transactional messages
which have been committed. If set to read_uncommitted (the default),
consumer.poll() will return all messages, even transactional messages which
have been aborted. Non-transactional messages will be returned unconditionally
in either mode. Messages will always be returned in offset order. Hence, in
read_committed mode, consumer.poll() will only return messages up to the
last stable offset (LSO), which is the one less than the offset of the first
open transaction. In particular any messages appearing after messages belonging
to ongoing transactions will be withheld until the relevant transaction has
been completed. As a result, read_committed consumers will not be able to
read up to the high watermark when there are in flight transactions. Further,
when in read_committed the seekToEnd method will return the LSO

Type: string
Default: read_uncommitted
Valid Values: [read_committed, read_uncommitted]
Importance: medium


max.poll.interval.ms
--------------------

The maximum delay between invocations of poll() when using consumer group
management. This places an upper bound on the amount of time that the consumer
can be idle before fetching more records. If poll() is not called before
expiration of this timeout, then the consumer is considered failed and the
group will rebalance in order to reassign the partitions to another member. For
consumers using a non-null group.instance.id which reach this timeout,
partitions will not be immediately reassigned. Instead, the consumer will stop
sending heartbeats and partitions will be reassigned after expiration of
session.timeout.ms. This mirrors the behavior of a static consumer which has
shutdown.

Type: int
Default: 300000 (5 minutes)
Valid Values: [1,...]
Importance: medium


max.poll.records
----------------

The maximum number of records returned in a single call to poll(). Note, that
max.poll.records does not impact the underlying fetching behavior. The
consumer will cache the records from each fetch request and returns them
incrementally from each poll.

Type: int
Default: 500
Valid Values: [1,...]
Importance: medium


partition.assignment.strategy
-----------------------------

A list of class names or class types, ordered by preference, of supported
partition assignment strategies that the client will use to distribute
partition ownership amongst consumer instances when group management is used.
Available options
are:

- org.apache.kafka.clients.consumer.RangeAssignor: Assigns partitions on a
per-topic basis.

- org.apache.kafka.clients.consumer.RoundRobinAssignor: Assigns partitions to
consumers in a round-robin fashion.

- org.apache.kafka.clients.consumer.StickyAssignor: Guarantees an assignment that
is maximally balanced while preserving as many existing partition assignments
as possible.

- org.apache.kafka.clients.consumer.CooperativeStickyAssignor: Follows the same
StickyAssignor logic, but allows for cooperative rebalancing.


The default assignor is [RangeAssignor, CooperativeStickyAssignor], which will
use the RangeAssignor by default, but allows upgrading to the
CooperativeStickyAssignor with just a single rolling bounce that removes the
RangeAssignor from the list.Implementing the
org.apache.kafka.clients.consumer.ConsumerPartitionAssignor interface allows
you to plug in a custom assignment strategy.

Type: list
Default: class org.apache.kafka.clients.consumer.RangeAssignor,class org.apache.kafka.clients.consumer.CooperativeStickyAssignor
Valid Values: non-null string
Importance: medium


receive.buffer.bytes
--------------------

The size of the TCP receive buffer (SO_RCVBUF) to use when reading data. If
the value is -1, the OS default will be used.

Type: int
Default: 65536 (64 kibibytes)
Valid Values: [-1,...]
Importance: medium


request.timeout.ms
------------------

The configuration controls the maximum amount of time the client will wait for
the response of a request. If the response is not received before the timeout
elapses the client will resend the request if necessary or fail the request if
retries are exhausted.

Type: int
Default: 30000 (30 seconds)
Valid Values: [0,...]
Importance: medium


sasl.client.callback.handler.class
----------------------------------

The fully qualified name of a SASL client callback handler class that
implements the AuthenticateCallbackHandler interface.

Type: class
Default: null
Valid Values:
Importance: medium


sasl.jaas.config
----------------

JAAS login context parameters for SASL connections in the format used by JAAS
configuration files. JAAS configuration file format is described <a
href=https://docs.oracle.com/javase/8/docs/technotes/guides/security/jgss/tutorials/LoginConfigFile.html>here</a>.
The format for the value is: loginModuleClass controlFlag
(optionName=optionValue);. For brokers, the config must be prefixed with
listener prefix and SASL mechanism name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.jaas.config=com.example.ScramLoginModule
required;

Type: password
Default: null
Valid Values:
Importance: medium


sasl.kerberos.service.name
--------------------------

The Kerberos principal name that Kafka runs as. This can be defined either in
Kafka's JAAS config or in Kafka's config.

Type: string
Default: null
Valid Values:
Importance: medium


sasl.login.callback.handler.class
---------------------------------

The fully qualified name of a SASL login callback handler class that implements
the AuthenticateCallbackHandler interface. For brokers, login callback handler
config must be prefixed with listener prefix and SASL mechanism name in
lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.callback.handler.class=com.example.CustomScramLoginCallbackHandler

Type: class
Default: null
Valid Values:
Importance: medium


sasl.login.class
----------------

The fully qualified name of a class that implements the Login interface. For
brokers, login config must be prefixed with listener prefix and SASL mechanism
name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.class=com.example.CustomScramLogin

Type: class
Default: null
Valid Values:
Importance: medium


sasl.mechanism
--------------

SASL mechanism used for client connections. This may be any mechanism for which
a security provider is available. GSSAPI is the default mechanism.

Type: string
Default: GSSAPI
Valid Values:
Importance: medium


sasl.oauthbearer.jwks.endpoint.url
----------------------------------

The OAuth/OIDC provider URL from which the provider's <a
href=https://datatracker.ietf.org/doc/html/rfc7517#section-5>JWKS (JSON Web
Key Set)</a> can be retrieved. The URL can be HTTP(S)-based or file-based. If
the URL is HTTP(S)-based, the JWKS data will be retrieved from the OAuth/OIDC
provider via the configured URL on broker startup. All then-current keys will
be cached on the broker for incoming requests. If an authentication request is
received for a JWT that includes a kid header claim value that isn't yet in
the cache, the JWKS endpoint will be queried again on demand. However, the
broker polls the URL every sasl.oauthbearer.jwks.endpoint.refresh.ms
milliseconds to refresh the cache with any forthcoming keys before any JWT
requests that include them are received. If the URL is file-based, the broker
will load the JWKS file from a configured location on startup. In the event
that the JWT includes a kid header value that isn't in the JWKS file, the
broker will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: medium


sasl.oauthbearer.token.endpoint.url
-----------------------------------

The URL for the OAuth/OIDC identity provider. If the URL is HTTP(S)-based, it
is the issuer's token endpoint URL to which requests will be made to login
based on the configuration in sasl.jaas.config. If the URL is file-based, it
specifies a file containing an access token (in JWT serialized form) issued by
the OAuth/OIDC identity provider to use for authorization.

Type: string
Default: null
Valid Values:
Importance: medium


security.protocol
-----------------

Protocol used to communicate with brokers. Valid values are: PLAINTEXT, SSL,
SASL_PLAINTEXT, SASL_SSL.

Type: string
Default: PLAINTEXT
Valid Values: (case insensitive) [SASL_SSL, PLAINTEXT, SSL, SASL_PLAINTEXT]
Importance: medium


send.buffer.bytes
-----------------

The size of the TCP send buffer (SO_SNDBUF) to use when sending data. If the
value is -1, the OS default will be used.

Type: int
Default: 131072 (128 kibibytes)
Valid Values: [-1,...]
Importance: medium


socket.connection.setup.timeout.max.ms
--------------------------------------

The maximum amount of time the client will wait for the socket connection to be
established. The connection setup timeout will increase exponentially for each
consecutive connection failure up to this maximum. To avoid connection storms,
a randomization factor of 0.2 will be applied to the timeout resulting in a
random range between 20% below and 20% above the computed value.

Type: long
Default: 30000 (30 seconds)
Valid Values:
Importance: medium


socket.connection.setup.timeout.ms
----------------------------------

The amount of time the client will wait for the socket connection to be
established. If the connection is not built before the timeout elapses, clients
will close the socket channel. This value is the initial backoff value and will
increase exponentially for each consecutive connection failure, up to the
socket.connection.setup.timeout.max.ms value.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: medium


ssl.enabled.protocols
---------------------

The list of protocols enabled for SSL connections. The default is
'TLSv1.2,TLSv1.3' when running with Java 11 or newer, 'TLSv1.2' otherwise. With
the default value for Java 11, clients and servers will prefer TLSv1.3 if both
support it and fallback to TLSv1.2 otherwise (assuming both support at least
TLSv1.2). This default should be fine for most cases. Also see the config
documentation for `ssl.protocol`.

Type: list
Default: TLSv1.2,TLSv1.3
Valid Values:
Importance: medium


ssl.keystore.type
-----------------

The file format of the key store file. This is optional for client. The values
currently supported by the default `ssl.engine.factory.class` are [JKS,
PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium


ssl.protocol
------------

The SSL protocol used to generate the SSLContext. The default is 'TLSv1.3' when
running with Java 11 or newer, 'TLSv1.2' otherwise. This value should be fine
for most use cases. Allowed values in recent JVMs are 'TLSv1.2' and 'TLSv1.3'.
'TLS', 'TLSv1.1', 'SSL', 'SSLv2' and 'SSLv3' may be supported in older JVMs,
but their usage is discouraged due to known security vulnerabilities.  With the
default value for this config and 'ssl.enabled.protocols', clients will
downgrade to 'TLSv1.2' if the server does not support 'TLSv1.3'. If this config
is set to 'TLSv1.2', clients will not use 'TLSv1.3' even if it is one of the
values in ssl.enabled.protocols and the server only supports 'TLSv1.3'.

Type: string
Default: TLSv1.3
Valid Values:
Importance: medium


ssl.provider
------------

The name of the security provider used for SSL connections. Default value is
the default security provider of the JVM.

Type: string
Default: null
Valid Values:
Importance: medium


ssl.truststore.type
-------------------

The file format of the trust store file. The values currently supported by the
default `ssl.engine.factory.class` are [JKS, PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium


auto.commit.interval.ms
-----------------------

The frequency in milliseconds that the consumer offsets are auto-committed to
Kafka if enable.auto.commit is set to true.

Type: int
Default: 5000 (5 seconds)
Valid Values: [0,...]
Importance: low


auto.include.jmx.reporter
-------------------------

Deprecated. Whether to automatically include JmxReporter even if it's not
listed in metric.reporters. This configuration will be removed in Kafka 4.0,
users should instead include org.apache.kafka.common.metrics.JmxReporter in
metric.reporters in order to enable the JmxReporter.

Type: boolean
Default: true
Valid Values:
Importance: low


check.crcs
----------

Automatically check the CRC32 of the records consumed. This ensures no
on-the-wire or on-disk corruption to the messages occurred. This check adds
some overhead, so it may be disabled in cases seeking extreme performance.

Type: boolean
Default: true
Valid Values:
Importance: low


client.id
---------

An id string to pass to the server when making requests. The purpose of this is
to be able to track the source of requests beyond just ip/port by allowing a
logical application name to be included in server-side request logging.

Type: string
Default:
Valid Values:
Importance: low


client.rack
-----------

A rack identifier for this client. This can be any string value which indicates
where this client is physically located. It corresponds with the broker config
'broker.rack'

Type: string
Default:
Valid Values:
Importance: low


enable.metrics.push
-------------------

Whether to enable pushing of client metrics to the cluster, if the cluster has
a client metrics subscription which matches this client.

Type: boolean
Default: true
Valid Values:
Importance: low


fetch.max.wait.ms
-----------------

The maximum amount of time the server will block before answering the fetch
request there isn't sufficient data to immediately satisfy the requirement
given by fetch.min.bytes. This config is used only for local log fetch. To tune
the remote fetch maximum wait time, please refer to 'remote.fetch.max.wait.ms'
broker config

Type: int
Default: 500
Valid Values: [0,...]
Importance: low


interceptor.classes
-------------------

A list of classes to use as interceptors. Implementing the
org.apache.kafka.clients.consumer.ConsumerInterceptor interface allows you to
intercept (and possibly mutate) records received by the consumer. By default,
there are no interceptors.

Type: list
Default:
Valid Values: non-null string
Importance: low


metadata.max.age.ms
-------------------

The period of time in milliseconds after which we force a refresh of metadata
even if we haven't seen any partition leadership changes to proactively
discover any new brokers or partitions.

Type: long
Default: 300000 (5 minutes)
Valid Values: [0,...]
Importance: low


metadata.recovery.strategy
--------------------------

Controls how the client recovers when none of the brokers known to it is
available. If set to none, the client fails. If set to rebootstrap, the
client repeats the bootstrap process using bootstrap.servers. Rebootstrapping
is useful when a client communicates with brokers so infrequently that the set
of brokers may change entirely before the client refreshes metadata. Metadata
recovery is triggered when all last-known brokers appear unavailable
simultaneously. Brokers appear unavailable when disconnected and no current
retry attempt is in-progress. Consider increasing reconnect.backoff.ms and
reconnect.backoff.max.ms and decreasing socket.connection.setup.timeout.ms
and socket.connection.setup.timeout.max.ms for the client.

Type: string
Default: none
Valid Values: (case insensitive) [REBOOTSTRAP, NONE]
Importance: low


metric.reporters
----------------

A list of classes to use as metrics reporters. Implementing the
org.apache.kafka.common.metrics.MetricsReporter interface allows plugging in
classes that will be notified of new metric creation. The JmxReporter is always
included to register JMX statistics.

Type: list
Default:
Valid Values: non-null string
Importance: low


metrics.num.samples
-------------------

The number of samples maintained to compute metrics.

Type: int
Default: 2
Valid Values: [1,...]
Importance: low


metrics.recording.level
-----------------------

The highest recording level for metrics.

Type: string
Default: INFO
Valid Values: [INFO, DEBUG, TRACE]
Importance: low


metrics.sample.window.ms
------------------------

The window of time a metrics sample is computed over.

Type: long
Default: 30000 (30 seconds)
Valid Values: [0,...]
Importance: low


reconnect.backoff.max.ms
------------------------

The maximum amount of time in milliseconds to wait when reconnecting to a
broker that has repeatedly failed to connect. If provided, the backoff per host
will increase exponentially for each consecutive connection failure, up to this
maximum. After calculating the backoff increase, 20% random jitter is added to
avoid connection storms.

Type: long
Default: 1000 (1 second)
Valid Values: [0,...]
Importance: low


reconnect.backoff.ms
--------------------

The base amount of time to wait before attempting to reconnect to a given host.
This avoids repeatedly connecting to a host in a tight loop. This backoff
applies to all connection attempts by the client to a broker. This value is the
initial backoff value and will increase exponentially for each consecutive
connection failure, up to the reconnect.backoff.max.ms value.

Type: long
Default: 50
Valid Values: [0,...]
Importance: low


retry.backoff.max.ms
--------------------

The maximum amount of time in milliseconds to wait when retrying a request to
the broker that has repeatedly failed. If provided, the backoff per client will
increase exponentially for each failed request, up to this maximum. To prevent
all clients from being synchronized upon retry, a randomized jitter with a
factor of 0.2 will be applied to the backoff, resulting in the backoff falling
within a range between 20% below and 20% above the computed value. If
retry.backoff.ms is set to be higher than retry.backoff.max.ms, then
retry.backoff.max.ms will be used as a constant backoff from the beginning
without any exponential increase

Type: long
Default: 1000 (1 second)
Valid Values: [0,...]
Importance: low


retry.backoff.ms
----------------

The amount of time to wait before attempting to retry a failed request to a
given topic partition. This avoids repeatedly sending requests in a tight loop
under some failure scenarios. This value is the initial backoff value and will
increase exponentially for each failed request, up to the
retry.backoff.max.ms value.

Type: long
Default: 100
Valid Values: [0,...]
Importance: low


sasl.kerberos.kinit.cmd
-----------------------

Kerberos kinit command path.

Type: string
Default: /usr/bin/kinit
Valid Values:
Importance: low


sasl.kerberos.min.time.before.relogin
-------------------------------------

Login thread sleep time between refresh attempts.

Type: long
Default: 60000
Valid Values:
Importance: low


sasl.kerberos.ticket.renew.jitter
---------------------------------

Percentage of random jitter added to the renewal time.

Type: double
Default: 0.05
Valid Values:
Importance: low


sasl.kerberos.ticket.renew.window.factor
----------------------------------------

Login thread will sleep until the specified window factor of time from last
refresh to ticket's expiry has been reached, at which time it will try to renew
the ticket.

Type: double
Default: 0.8
Valid Values:
Importance: low


sasl.login.connect.timeout.ms
-----------------------------

The (optional) value in milliseconds for the external authentication provider
connection timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low


sasl.login.read.timeout.ms
--------------------------

The (optional) value in milliseconds for the external authentication provider
read timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low


sasl.login.refresh.buffer.seconds
---------------------------------

The amount of buffer time before credential expiration to maintain when
refreshing a credential, in seconds. If a refresh would otherwise occur closer
to expiration than the number of buffer seconds then the refresh will be moved
up to maintain as much of the buffer time as possible. Legal values are between
0 and 3600 (1 hour); a default value of 300 (5 minutes) is used if no value is
specified. This value and sasl.login.refresh.min.period.seconds are both
ignored if their sum exceeds the remaining lifetime of a credential. Currently
applies only to OAUTHBEARER.

Type: short
Default: 300
Valid Values: [0,...,3600]
Importance: low


sasl.login.refresh.min.period.seconds
-------------------------------------

The desired minimum time for the login refresh thread to wait before refreshing
a credential, in seconds. Legal values are between 0 and 900 (15 minutes); a
default value of 60 (1 minute) is used if no value is specified. This value and
sasl.login.refresh.buffer.seconds are both ignored if their sum exceeds the
remaining lifetime of a credential. Currently applies only to OAUTHBEARER.

Type: short
Default: 60
Valid Values: [0,...,900]
Importance: low


sasl.login.refresh.window.factor
--------------------------------

Login refresh thread will sleep until the specified window factor relative to
the credential's lifetime has been reached, at which time it will try to
refresh the credential. Legal values are between 0.5 (50%) and 1.0 (100%)
inclusive; a default value of 0.8 (80%) is used if no value is specified.
Currently applies only to OAUTHBEARER.

Type: double
Default: 0.8
Valid Values: [0.5,...,1.0]
Importance: low


sasl.login.refresh.window.jitter
--------------------------------

The maximum amount of random jitter relative to the credential's lifetime that
is added to the login refresh thread's sleep time. Legal values are between 0
and 0.25 (25%) inclusive; a default value of 0.05 (5%) is used if no value is
specified. Currently applies only to OAUTHBEARER.

Type: double
Default: 0.05
Valid Values: [0.0,...,0.25]
Importance: low


sasl.login.retry.backoff.max.ms
-------------------------------

The (optional) value in milliseconds for the maximum wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low


sasl.login.retry.backoff.ms
---------------------------

The (optional) value in milliseconds for the initial wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 100
Valid Values:
Importance: low


sasl.oauthbearer.clock.skew.seconds
-----------------------------------

The (optional) value in seconds to allow for differences between the time of
the OAuth/OIDC identity provider and the broker.

Type: int
Default: 30
Valid Values:
Importance: low


sasl.oauthbearer.expected.audience
----------------------------------

The (optional) comma-delimited setting for the broker to use to verify that the
JWT was issued for one of the expected audiences. The JWT will be inspected for
the standard OAuth aud claim and if this value is set, the broker will
match the value from JWT's aud claim to see if there is an exact match. If
there is no match, the broker will reject the JWT and authentication will fail.

Type: list
Default: null
Valid Values:
Importance: low


sasl.oauthbearer.expected.issuer
--------------------------------

The (optional) setting for the broker to use to verify that the JWT was created
by the expected issuer. The JWT will be inspected for the standard OAuth
iss claim and if this value is set, the broker will match it exactly
against what is in the JWT's iss claim. If there is no match, the broker
will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.refresh.ms
-----------------------------------------

The (optional) value in milliseconds for the broker to wait between refreshing
its JWKS (JSON Web Key Set) cache that contains the keys to verify the
signature of the JWT.

Type: long
Default: 3600000 (1 hour)
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms
---------------------------------------------------

The (optional) value in milliseconds for the maximum wait between attempts to
retrieve the JWKS (JSON Web Key Set) from the external authentication provider.
JWKS retrieval uses an exponential backoff algorithm with an initial wait based
on the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double
in wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.retry.backoff.ms
-----------------------------------------------

The (optional) value in milliseconds for the initial wait between JWKS (JSON
Web Key Set) retrieval attempts from the external authentication provider. JWKS
retrieval uses an exponential backoff algorithm with an initial wait based on
the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double in
wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 100
Valid Values:
Importance: low


sasl.oauthbearer.scope.claim.name
---------------------------------

The OAuth claim for the scope is often named scope, but this (optional)
setting can provide a different name to use for the scope included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: scope
Valid Values:
Importance: low


sasl.oauthbearer.sub.claim.name
-------------------------------

The OAuth claim for the subject is often named sub, but this (optional)
setting can provide a different name to use for the subject included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: sub
Valid Values:
Importance: low


security.providers
------------------

A list of configurable creator classes each returning a provider implementing
security algorithms. These classes should implement the
org.apache.kafka.common.security.auth.SecurityProviderCreator interface.

Type: string
Default: null
Valid Values:
Importance: low


ssl.cipher.suites
-----------------

A list of cipher suites. This is a named combination of authentication,
encryption, MAC and key exchange algorithm used to negotiate the security
settings for a network connection using TLS or SSL network protocol. By default
all the available cipher suites are supported.

Type: list
Default: null
Valid Values:
Importance: low


ssl.endpoint.identification.algorithm
-------------------------------------

The endpoint identification algorithm to validate server hostname using server
certificate.

Type: string
Default: https
Valid Values:
Importance: low


ssl.engine.factory.class
------------------------

The class of type org.apache.kafka.common.security.auth.SslEngineFactory to
provide SSLEngine objects. Default value is
org.apache.kafka.common.security.ssl.DefaultSslEngineFactory. Alternatively,
setting this to
org.apache.kafka.common.security.ssl.CommonNameLoggingSslEngineFactory will log
the common name of expired SSL certificates used by clients to authenticate at
any of the brokers with log level INFO. Note that this will cause a tiny delay
during establishment of new connections from mTLS clients to brokers due to the
extra code for examining the certificate chain provided by the client. Note
further that the implementation uses a custom truststore based on the standard
Java truststore and thus might be considered a security risk due to not being
as mature as the standard one.

Type: class
Default: null
Valid Values:
Importance: low


ssl.keymanager.algorithm
------------------------

The algorithm used by key manager factory for SSL connections. Default value is
the key manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: SunX509
Valid Values:
Importance: low


ssl.secure.random.implementation
--------------------------------

The SecureRandom PRNG implementation to use for SSL cryptography operations.

Type: string
Default: null
Valid Values:
Importance: low


ssl.trustmanager.algorithm
--------------------------

The algorithm used by trust manager factory for SSL connections. Default value
is the trust manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: PKIX
Valid Values:
Importance: low


group.id
--------

A unique string that identifies the Connect cluster group this worker belongs
to.

Type: string
Default:
Valid Values:
Importance: high


key.converter
-------------

Converter class used to convert between Kafka Connect format and the serialized
form that is written to Kafka. This controls the format of the keys in messages
written to or read from Kafka, and since this is independent of connectors it
allows any connector to work with any serialization format. Examples of common
formats include JSON and Avro.

Type: class
Default:
Valid Values:
Importance: high


offset.storage.topic
--------------------

The name of the Kafka topic where source connector offsets are stored

Type: string
Default:
Valid Values:
Importance: high


status.storage.topic
--------------------

The name of the Kafka topic where connector and task status are stored

Type: string
Default:
Valid Values:
Importance: high


value.converter
---------------

Converter class used to convert between Kafka Connect format and the serialized
form that is written to Kafka. This controls the format of the values in
messages written to or read from Kafka, and since this is independent of
connectors it allows any connector to work with any serialization format.
Examples of common formats include JSON and Avro.

Type: class
Default:
Valid Values:
Importance: high


bootstrap.servers
-----------------

A list of host/port pairs to use for establishing the initial connection to the
Kafka cluster. The client will make use of all servers irrespective of which
servers are specified here for bootstrapping&mdash;this list only impacts the
initial hosts used to discover the full set of servers. This list should be in
the form host1:port1,host2:port2,.... Since these servers are just used for
the initial connection to discover the full cluster membership (which may
change dynamically), this list need not contain the full set of servers (you
may want more than one, though, in case a server is down).

Type: list
Default: localhost:9092
Valid Values:
Importance: high


exactly.once.source.support
---------------------------

Whether to enable exactly-once support for source connectors in the cluster by
using transactions to write source records and their source offsets, and by
proactively fencing out old task generations before bringing up new ones.

To
enable exactly-once source support on a new cluster, set this property to
'enabled'. To enable support on an existing cluster, first set to 'preparing'
on every worker in the cluster, then set to 'enabled'. A rolling upgrade may be
used for both changes. For more information on this feature, see the <a
href=https://kafka.apache.org/documentation.html#connect_exactlyoncesource>exactly-once
source support documentation</a>.

Type: string
Default: disabled
Valid Values: (case insensitive) [DISABLED, ENABLED, PREPARING]
Importance: high


heartbeat.interval.ms
---------------------

The expected time between heartbeats to the group coordinator when using
Kafka's group management facilities. Heartbeats are used to ensure that the
worker's session stays active and to facilitate rebalancing when new members
join or leave the group. The value must be set lower than session.timeout.ms,
but typically should be set no higher than 1/3 of that value. It can be
adjusted even lower to control the expected time for normal rebalances.

Type: int
Default: 3000 (3 seconds)
Valid Values:
Importance: high


rebalance.timeout.ms
--------------------

The maximum allowed time for each worker to join the group once a rebalance has
begun. This is basically a limit on the amount of time needed for all tasks to
flush any pending data and commit offsets. If the timeout is exceeded, then the
worker will be removed from the group, which will cause offset commit failures.

Type: int
Default: 60000 (1 minute)
Valid Values:
Importance: high


session.timeout.ms
------------------

The timeout used to detect worker failures. The worker sends periodic
heartbeats to indicate its liveness to the broker. If no heartbeats are
received by the broker before the expiration of this session timeout, then the
broker will remove the worker from the group and initiate a rebalance. Note
that the value must be in the allowable range as configured in the broker
configuration by group.min.session.timeout.ms and
group.max.session.timeout.ms.

Type: int
Default: 10000 (10 seconds)
Valid Values:
Importance: high


ssl.key.password
----------------

The password of the private key in the key store file or the PEM key specified
in 'ssl.keystore.key'.

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.certificate.chain
------------------------------

Certificate chain in the format specified by 'ssl.keystore.type'. Default SSL
engine factory supports only PEM format with a list of X.509 certificates

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.key
----------------

Private key in the format specified by 'ssl.keystore.type'. Default SSL engine
factory supports only PEM format with PKCS#8 keys. If the key is encrypted, key
password must be specified using 'ssl.key.password'

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.location
---------------------

The location of the key store file. This is optional for client and can be used
for two-way authentication for client.

Type: string
Default: null
Valid Values:
Importance: high


ssl.keystore.password
---------------------

The store password for the key store file. This is optional for client and only
needed if 'ssl.keystore.location' is configured. Key store password is not
supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: high


ssl.truststore.certificates
---------------------------

Trusted certificates in the format specified by 'ssl.truststore.type'. Default
SSL engine factory supports only PEM format with X.509 certificates.

Type: password
Default: null
Valid Values:
Importance: high


ssl.truststore.location
-----------------------

The location of the trust store file.

Type: string
Default: null
Valid Values:
Importance: high


ssl.truststore.password
-----------------------

The password for the trust store file. If a password is not set, trust store
file configured will still be used, but integrity checking is disabled. Trust
store password is not supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: high


client.dns.lookup
-----------------

Controls how the client uses DNS lookups. If set to use_all_dns_ips,
connect to each returned IP address in sequence until a successful connection
is established. After a disconnection, the next IP is used. Once all IPs have
been used once, the client resolves the IP(s) from the hostname again (both the
JVM and the OS cache DNS name lookups, however). If set to
resolve_canonical_bootstrap_servers_only, resolve each bootstrap address
into a list of canonical names. After the bootstrap phase, this behaves the
same as use_all_dns_ips.

Type: string
Default: use_all_dns_ips
Valid Values: [use_all_dns_ips, resolve_canonical_bootstrap_servers_only]
Importance: medium


connections.max.idle.ms
-----------------------

Close idle connections after the number of milliseconds specified by this
config.

Type: long
Default: 540000 (9 minutes)
Valid Values:
Importance: medium


connector.client.config.override.policy
---------------------------------------

Class name or alias of implementation of ConnectorClientConfigOverridePolicy.
Defines what client configurations can be overridden by the connector. The
default implementation is `All`, meaning connector configurations can
override all client properties. The other possible policies in the framework
include `None` to disallow connectors from overriding client properties, and
`Principal` to allow connectors to override only client principals.

Type: string
Default: All
Valid Values:
Importance: medium


receive.buffer.bytes
--------------------

The size of the TCP receive buffer (SO_RCVBUF) to use when reading data. If
the value is -1, the OS default will be used.

Type: int
Default: 32768 (32 kibibytes)
Valid Values: [-1,...]
Importance: medium


request.timeout.ms
------------------

The configuration controls the maximum amount of time the client will wait for
the response of a request. If the response is not received before the timeout
elapses the client will resend the request if necessary or fail the request if
retries are exhausted.

Type: int
Default: 40000 (40 seconds)
Valid Values: [0,...]
Importance: medium


sasl.client.callback.handler.class
----------------------------------

The fully qualified name of a SASL client callback handler class that
implements the AuthenticateCallbackHandler interface.

Type: class
Default: null
Valid Values:
Importance: medium


sasl.jaas.config
----------------

JAAS login context parameters for SASL connections in the format used by JAAS
configuration files. JAAS configuration file format is described <a
href=https://docs.oracle.com/javase/8/docs/technotes/guides/security/jgss/tutorials/LoginConfigFile.html>here</a>.
The format for the value is: loginModuleClass controlFlag
(optionName=optionValue);. For brokers, the config must be prefixed with
listener prefix and SASL mechanism name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.jaas.config=com.example.ScramLoginModule
required;

Type: password
Default: null
Valid Values:
Importance: medium


sasl.kerberos.service.name
--------------------------

The Kerberos principal name that Kafka runs as. This can be defined either in
Kafka's JAAS config or in Kafka's config.

Type: string
Default: null
Valid Values:
Importance: medium


sasl.login.callback.handler.class
---------------------------------

The fully qualified name of a SASL login callback handler class that implements
the AuthenticateCallbackHandler interface. For brokers, login callback handler
config must be prefixed with listener prefix and SASL mechanism name in
lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.callback.handler.class=com.example.CustomScramLoginCallbackHandler

Type: class
Default: null
Valid Values:
Importance: medium


sasl.login.class
----------------

The fully qualified name of a class that implements the Login interface. For
brokers, login config must be prefixed with listener prefix and SASL mechanism
name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.class=com.example.CustomScramLogin

Type: class
Default: null
Valid Values:
Importance: medium


sasl.mechanism
--------------

SASL mechanism used for client connections. This may be any mechanism for which
a security provider is available. GSSAPI is the default mechanism.

Type: string
Default: GSSAPI
Valid Values:
Importance: medium


sasl.oauthbearer.jwks.endpoint.url
----------------------------------

The OAuth/OIDC provider URL from which the provider's <a
href=https://datatracker.ietf.org/doc/html/rfc7517#section-5>JWKS (JSON Web
Key Set)</a> can be retrieved. The URL can be HTTP(S)-based or file-based. If
the URL is HTTP(S)-based, the JWKS data will be retrieved from the OAuth/OIDC
provider via the configured URL on broker startup. All then-current keys will
be cached on the broker for incoming requests. If an authentication request is
received for a JWT that includes a kid header claim value that isn't yet in
the cache, the JWKS endpoint will be queried again on demand. However, the
broker polls the URL every sasl.oauthbearer.jwks.endpoint.refresh.ms
milliseconds to refresh the cache with any forthcoming keys before any JWT
requests that include them are received. If the URL is file-based, the broker
will load the JWKS file from a configured location on startup. In the event
that the JWT includes a kid header value that isn't in the JWKS file, the
broker will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: medium


sasl.oauthbearer.token.endpoint.url
-----------------------------------

The URL for the OAuth/OIDC identity provider. If the URL is HTTP(S)-based, it
is the issuer's token endpoint URL to which requests will be made to login
based on the configuration in sasl.jaas.config. If the URL is file-based, it
specifies a file containing an access token (in JWT serialized form) issued by
the OAuth/OIDC identity provider to use for authorization.

Type: string
Default: null
Valid Values:
Importance: medium


security.protocol
-----------------

Protocol used to communicate with brokers. Valid values are: PLAINTEXT, SSL,
SASL_PLAINTEXT, SASL_SSL.

Type: string
Default: PLAINTEXT
Valid Values: (case insensitive) [SASL_SSL, PLAINTEXT, SSL, SASL_PLAINTEXT]
Importance: medium


send.buffer.bytes
-----------------

The size of the TCP send buffer (SO_SNDBUF) to use when sending data. If the
value is -1, the OS default will be used.

Type: int
Default: 131072 (128 kibibytes)
Valid Values: [-1,...]
Importance: medium


ssl.enabled.protocols
---------------------

The list of protocols enabled for SSL connections. The default is
'TLSv1.2,TLSv1.3' when running with Java 11 or newer, 'TLSv1.2' otherwise. With
the default value for Java 11, clients and servers will prefer TLSv1.3 if both
support it and fallback to TLSv1.2 otherwise (assuming both support at least
TLSv1.2). This default should be fine for most cases. Also see the config
documentation for `ssl.protocol`.

Type: list
Default: TLSv1.2,TLSv1.3
Valid Values:
Importance: medium


ssl.keystore.type
-----------------

The file format of the key store file. This is optional for client. The values
currently supported by the default `ssl.engine.factory.class` are [JKS,
PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium


ssl.protocol
------------

The SSL protocol used to generate the SSLContext. The default is 'TLSv1.3' when
running with Java 11 or newer, 'TLSv1.2' otherwise. This value should be fine
for most use cases. Allowed values in recent JVMs are 'TLSv1.2' and 'TLSv1.3'.
    'TLS', 'TLSv1.1', 'SSL', 'SSLv2' and 'SSLv3' may be supported in older
    JVMs, but their usage is discouraged due to known security vulnerabilities.
    With the default value for this config and 'ssl.enabled.protocols', clients
    will downgrade to 'TLSv1.2' if the server does not support 'TLSv1.3'. If
    this config is set to 'TLSv1.2', clients will not use 'TLSv1.3' even if it
    is one of the values in ssl.enabled.protocols and the server only supports
    'TLSv1.3'.

Type: string
Default: TLSv1.3
Valid Values:
Importance: medium


ssl.provider
------------

The name of the security provider used for SSL connections. Default value is
the default security provider of the JVM.

Type: string
Default: null
Valid Values:
Importance: medium


ssl.truststore.type
-------------------

The file format of the trust store file. The values currently supported by the
default `ssl.engine.factory.class` are [JKS, PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium


worker.sync.timeout.ms
----------------------

When the worker is out of sync with other workers and needs to resynchronize
configurations, wait up to this amount of time before giving up, leaving the
group, and waiting a backoff period before rejoining.

Type: int
Default: 3000 (3 seconds)
Valid Values:
Importance: medium


worker.unsync.backoff.ms
------------------------

When the worker is out of sync with other workers and fails to catch up within
worker.sync.timeout.ms, leave the Connect cluster for this long before
rejoining.

Type: int
Default: 300000 (5 minutes)
Valid Values:
Importance: medium


access.control.allow.methods
----------------------------

Sets the methods supported for cross origin requests by setting the
Access-Control-Allow-Methods header. The default value of the
Access-Control-Allow-Methods header allows cross origin requests for GET, POST
and HEAD.

Type: string
Default:
Valid Values:
Importance: low


access.control.allow.origin
---------------------------

Value to set the Access-Control-Allow-Origin header to for REST API requests.To
enable cross origin access, set this to the domain of the application that
should be permitted to access the API, or '' to allow access from any domain.
The default value only allows access from the domain of the REST API.

Type: string
Default:
Valid Values:
Importance: low


admin.listeners
---------------

List of comma-separated URIs the Admin REST API will listen on. The supported
protocols are HTTP and HTTPS. An empty or blank string will disable this
feature. The default behavior is to use the regular listener (specified by the
'listeners' property).

Type: list
Default: null
Valid Values: List of comma-separated URLs, ex: http://localhost:8080,https://localhost:8443.
Importance: low


auto.include.jmx.reporter
-------------------------

Deprecated. Whether to automatically include JmxReporter even if it's not
listed in metric.reporters. This configuration will be removed in Kafka 4.0,
users should instead include org.apache.kafka.common.metrics.JmxReporter in
metric.reporters in order to enable the JmxReporter.

Type: boolean
Default: true
Valid Values:
Importance: low


client.id
---------

An id string to pass to the server when making requests. The purpose of this is
to be able to track the source of requests beyond just ip/port by allowing a
logical application name to be included in server-side request logging.

Type: string
Default:
Valid Values:
Importance: low


config.providers
----------------

Comma-separated names of ConfigProvider classes, loaded and used in the order
specified. Implementing the interface ConfigProvider allows you to replace
variable references in connector configurations, such as for externalized
secrets.

Type: list
Default:
Valid Values:
Importance: low


config.storage.replication.factor
---------------------------------

Replication factor used when creating the configuration storage topic

Type: short
Default: 3
Valid Values: Positive number not larger than the number of brokers in the Kafka cluster, or -1 to use the broker's default
Importance: low


connect.protocol
----------------

Compatibility mode for Kafka Connect Protocol

Type: string
Default: sessioned
Valid Values: [eager, compatible, sessioned]
Importance: low


header.converter
----------------

HeaderConverter class used to convert between Kafka Connect format and the
serialized form that is written to Kafka. This controls the format of the
header values in messages written to or read from Kafka, and since this is
independent of connectors it allows any connector to work with any
serialization format. Examples of common formats include JSON and Avro. By
default, the SimpleHeaderConverter is used to serialize header values to
strings and deserialize them by inferring the schemas.

Type: class
Default: org.apache.kafka.connect.storage.SimpleHeaderConverter
Valid Values:
Importance: low


inter.worker.key.generation.algorithm
-------------------------------------

The algorithm to use for generating internal request keys. The algorithm
'HmacSHA256' will be used as a default on JVMs that support it; on other JVMs,
no default is used and a value for this property must be manually specified in
the worker config.

Type: string
Default: HmacSHA256
Valid Values: Any KeyGenerator algorithm supported by the worker JVM
Importance: low


inter.worker.key.size
---------------------

The size of the key to use for signing internal requests, in bits. If null, the
default key size for the key generation algorithm will be used.

Type: int
Default: null
Valid Values:
Importance: low


inter.worker.key.ttl.ms
-----------------------

The TTL of generated session keys used for internal request validation (in
milliseconds)

Type: int
Default: 3600000 (1 hour)
Valid Values: [0,...,2147483647]
Importance: low


inter.worker.signature.algorithm
--------------------------------

The algorithm used to sign internal requestsThe algorithm
'inter.worker.signature.algorithm' will be used as a default on JVMs that
support it; on other JVMs, no default is used and a value for this property
must be manually specified in the worker config.

Type: string
Default: HmacSHA256
Valid Values: Any MAC algorithm supported by the worker JVM
Importance: low


inter.worker.verification.algorithms
------------------------------------

A list of permitted algorithms for verifying internal requests, which must
include the algorithm used for the inter.worker.signature.algorithm property.
The algorithm(s) '[HmacSHA256]' will be used as a default on JVMs that
provide them; on other JVMs, no default is used and a value for this property
must be manually specified in the worker config.

Type: list
Default: HmacSHA256
Valid Values: A list of one or more MAC algorithms, each supported by the worker JVM
Importance: low


listeners
---------

List of comma-separated URIs the REST API will listen on. The supported
protocols are HTTP and HTTPS.

 Specify hostname as 0.0.0.0 to bind to all
interfaces.

 Leave hostname empty to bind to default interface.

 Examples
of legal listener lists: HTTP://myhost:8083,HTTPS://myhost:8084

Type: list
Default: http://:8083
Valid Values: List of comma-separated URLs, ex: http://localhost:8080,https://localhost:8443.
Importance: low


metadata.max.age.ms
-------------------

The period of time in milliseconds after which we force a refresh of metadata
even if we haven't seen any partition leadership changes to proactively
discover any new brokers or partitions.

Type: long
Default: 300000 (5 minutes)
Valid Values: [0,...]
Importance: low


metadata.recovery.strategy
--------------------------

Controls how the client recovers when none of the brokers known to it is
available. If set to none, the client fails. If set to rebootstrap, the
client repeats the bootstrap process using bootstrap.servers. Rebootstrapping
is useful when a client communicates with brokers so infrequently that the set
of brokers may change entirely before the client refreshes metadata. Metadata
recovery is triggered when all last-known brokers appear unavailable
simultaneously. Brokers appear unavailable when disconnected and no current
retry attempt is in-progress. Consider increasing reconnect.backoff.ms and
reconnect.backoff.max.ms and decreasing socket.connection.setup.timeout.ms
and socket.connection.setup.timeout.max.ms for the client.

Type: string
Default: none
Valid Values: (case insensitive) [REBOOTSTRAP, NONE]
Importance: low


metric.reporters
----------------

A list of classes to use as metrics reporters. Implementing the
org.apache.kafka.common.metrics.MetricsReporter interface allows plugging in
classes that will be notified of new metric creation. The JmxReporter is always
included to register JMX statistics.

Type: list
Default:
Valid Values:
Importance: low


metrics.num.samples
-------------------

The number of samples maintained to compute metrics.

Type: int
Default: 2
Valid Values: [1,...]
Importance: low


metrics.recording.level
-----------------------

The highest recording level for metrics.

Type: string
Default: INFO
Valid Values: [INFO, DEBUG]
Importance: low


metrics.sample.window.ms
------------------------

The window of time a metrics sample is computed over.

Type: long
Default: 30000 (30 seconds)
Valid Values: [0,...]
Importance: low


offset.flush.interval.ms
------------------------

Interval at which to try committing offsets for tasks.

Type: long
Default: 60000 (1 minute)
Valid Values:
Importance: low


offset.flush.timeout.ms
-----------------------

Maximum number of milliseconds to wait for records to flush and partition
offset data to be committed to offset storage before cancelling the process and
restoring the offset data to be committed in a future attempt. This property
has no effect for source connectors running with exactly-once support.

Type: long
Default: 5000 (5 seconds)
Valid Values:
Importance: low


offset.storage.partitions
-------------------------

The number of partitions used when creating the offset storage topic

Type: int
Default: 25
Valid Values: Positive number, or -1 to use the broker's default
Importance: low


offset.storage.replication.factor
---------------------------------

Replication factor used when creating the offset storage topic

Type: short
Default: 3
Valid Values: Positive number not larger than the number of brokers in the Kafka cluster, or -1 to use the broker's default
Importance: low


plugin.discovery
----------------

Method to use to discover plugins present in the classpath and plugin.path
configuration. This can be one of multiple values with the following
meanings:

 only_scan: Discover plugins only by reflection. Plugins which
are not discoverable by ServiceLoader will not impact worker startup.


hybrid_warn: Discover plugins reflectively and by ServiceLoader. Plugins which
are not discoverable by ServiceLoader will print warnings during worker
startup.

 hybrid_fail: Discover plugins reflectively and by ServiceLoader.
Plugins which are not discoverable by ServiceLoader will cause worker startup
to fail.

 service_load: Discover plugins only by ServiceLoader. Faster
startup than other modes. Plugins which are not discoverable by ServiceLoader
may not be usable.

Type: string
Default: hybrid_warn
Valid Values: (case insensitive) [ONLY_SCAN, SERVICE_LOAD, HYBRID_WARN, HYBRID_FAIL]
Importance: low


plugin.path
-----------

List of paths separated by commas (,) that contain plugins (connectors,
converters, transformations). The list should consist of top level directories
that include any combination of:

a) directories immediately containing jars
with plugins and their dependencies

b) uber-jars with plugins and their
dependencies

c) directories immediately containing the package directory
structure of classes of plugins and their dependencies

Note: symlinks will
be followed to discover dependencies or plugins.

Examples:
plugin.path=/usr/local/share/java,/usr/local/share/kafka/plugins,/opt/connectors

Do
not use config provider variables in this property, since the raw path is used
by the worker's scanner before config providers are initialized and used to
replace variables.

Type: list
Default: null
Valid Values:
Importance: low


reconnect.backoff.max.ms
------------------------

The maximum amount of time in milliseconds to wait when reconnecting to a
broker that has repeatedly failed to connect. If provided, the backoff per host
will increase exponentially for each consecutive connection failure, up to this
maximum. After calculating the backoff increase, 20% random jitter is added to
avoid connection storms.

Type: long
Default: 1000 (1 second)
Valid Values: [0,...]
Importance: low


reconnect.backoff.ms
--------------------

The base amount of time to wait before attempting to reconnect to a given host.
This avoids repeatedly connecting to a host in a tight loop. This backoff
applies to all connection attempts by the client to a broker. This value is the
initial backoff value and will increase exponentially for each consecutive
connection failure, up to the reconnect.backoff.max.ms value.

Type: long
Default: 50
Valid Values: [0,...]
Importance: low


response.http.headers.config
----------------------------

Rules for REST API HTTP response headers

Type: string
Default:
Valid Values: Comma-separated header rules, where each header rule is of the form '[action] [header name]:[header value]' and optionally surrounded by double quotes if any part of a header rule contains a comma
Importance: low


rest.advertised.host.name
-------------------------

If this is set, this is the hostname that will be given out to other workers to
connect to.

Type: string
Default: null
Valid Values:
Importance: low


rest.advertised.listener
------------------------

Sets the advertised listener (HTTP or HTTPS) which will be given to other
workers to use.

Type: string
Default: null
Valid Values:
Importance: low


rest.advertised.port
--------------------

If this is set, this is the port that will be given out to other workers to
connect to.

Type: int
Default: null
Valid Values:
Importance: low


rest.extension.classes
----------------------

Comma-separated names of ConnectRestExtension classes, loaded and called in
the order specified. Implementing the interface ConnectRestExtension allows
you to inject into Connect's REST API user defined resources like filters.
Typically used to add custom capability like logging, security, etc.

Type: list
Default:
Valid Values:
Importance: low


retry.backoff.max.ms
--------------------

The maximum amount of time in milliseconds to wait when retrying a request to
the broker that has repeatedly failed. If provided, the backoff per client will
increase exponentially for each failed request, up to this maximum. To prevent
all clients from being synchronized upon retry, a randomized jitter with a
factor of 0.2 will be applied to the backoff, resulting in the backoff falling
within a range between 20% below and 20% above the computed value. If
retry.backoff.ms is set to be higher than retry.backoff.max.ms, then
retry.backoff.max.ms will be used as a constant backoff from the beginning
without any exponential increase

Type: long
Default: 1000 (1 second)
Valid Values: [0,...]
Importance: low


retry.backoff.ms
----------------

The amount of time to wait before attempting to retry a failed request to a
given topic partition. This avoids repeatedly sending requests in a tight loop
under some failure scenarios. This value is the initial backoff value and will
increase exponentially for each failed request, up to the
retry.backoff.max.ms value.

Type: long
Default: 100
Valid Values: [0,...]
Importance: low


sasl.kerberos.kinit.cmd
-----------------------

Kerberos kinit command path.

Type: string
Default: /usr/bin/kinit
Valid Values:
Importance: low


sasl.kerberos.min.time.before.relogin
-------------------------------------

Login thread sleep time between refresh attempts.

Type: long
Default: 60000
Valid Values:
Importance: low


sasl.kerberos.ticket.renew.jitter
---------------------------------

Percentage of random jitter added to the renewal time.

Type: double
Default: 0.05
Valid Values:
Importance: low


sasl.kerberos.ticket.renew.window.factor
----------------------------------------

Login thread will sleep until the specified window factor of time from last
refresh to ticket's expiry has been reached, at which time it will try to renew
the ticket.

Type: double
Default: 0.8
Valid Values:
Importance: low


sasl.login.connect.timeout.ms
-----------------------------

The (optional) value in milliseconds for the external authentication provider
connection timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low


sasl.login.read.timeout.ms
--------------------------

The (optional) value in milliseconds for the external authentication provider
read timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low


sasl.login.refresh.buffer.seconds
---------------------------------

The amount of buffer time before credential expiration to maintain when
refreshing a credential, in seconds. If a refresh would otherwise occur closer
to expiration than the number of buffer seconds then the refresh will be moved
up to maintain as much of the buffer time as possible. Legal values are between
0 and 3600 (1 hour); a default value of 300 (5 minutes) is used if no value is
specified. This value and sasl.login.refresh.min.period.seconds are both
ignored if their sum exceeds the remaining lifetime of a credential. Currently
applies only to OAUTHBEARER.

Type: short
Default: 300
Valid Values: [0,...,3600]
Importance: low


sasl.login.refresh.min.period.seconds
-------------------------------------

The desired minimum time for the login refresh thread to wait before refreshing
a credential, in seconds. Legal values are between 0 and 900 (15 minutes); a
default value of 60 (1 minute) is used if no value is specified. This value and
sasl.login.refresh.buffer.seconds are both ignored if their sum exceeds the
remaining lifetime of a credential. Currently applies only to OAUTHBEARER.

Type: short
Default: 60
Valid Values: [0,...,900]
Importance: low


sasl.login.refresh.window.factor
--------------------------------

Login refresh thread will sleep until the specified window factor relative to
the credential's lifetime has been reached, at which time it will try to
refresh the credential. Legal values are between 0.5 (50%) and 1.0 (100%)
inclusive; a default value of 0.8 (80%) is used if no value is specified.
Currently applies only to OAUTHBEARER.

Type: double
Default: 0.8
Valid Values: [0.5,...,1.0]
Importance: low


sasl.login.refresh.window.jitter
--------------------------------

The maximum amount of random jitter relative to the credential's lifetime that
is added to the login refresh thread's sleep time. Legal values are between 0
and 0.25 (25%) inclusive; a default value of 0.05 (5%) is used if no value is
specified. Currently applies only to OAUTHBEARER.

Type: double
Default: 0.05
Valid Values: [0.0,...,0.25]
Importance: low


sasl.login.retry.backoff.max.ms
-------------------------------

The (optional) value in milliseconds for the maximum wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low


sasl.login.retry.backoff.ms
---------------------------

The (optional) value in milliseconds for the initial wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 100
Valid Values:
Importance: low


sasl.oauthbearer.clock.skew.seconds
-----------------------------------

The (optional) value in seconds to allow for differences between the time of
the OAuth/OIDC identity provider and the broker.

Type: int
Default: 30
Valid Values:
Importance: low


sasl.oauthbearer.expected.audience
----------------------------------

The (optional) comma-delimited setting for the broker to use to verify that the
JWT was issued for one of the expected audiences. The JWT will be inspected for
the standard OAuth aud claim and if this value is set, the broker will
match the value from JWT's aud claim to see if there is an exact match. If
there is no match, the broker will reject the JWT and authentication will fail.

Type: list
Default: null
Valid Values:
Importance: low


sasl.oauthbearer.expected.issuer
--------------------------------

The (optional) setting for the broker to use to verify that the JWT was created
by the expected issuer. The JWT will be inspected for the standard OAuth
iss claim and if this value is set, the broker will match it exactly
against what is in the JWT's iss claim. If there is no match, the broker
will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.refresh.ms
-----------------------------------------

The (optional) value in milliseconds for the broker to wait between refreshing
its JWKS (JSON Web Key Set) cache that contains the keys to verify the
signature of the JWT.

Type: long
Default: 3600000 (1 hour)
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms
---------------------------------------------------

The (optional) value in milliseconds for the maximum wait between attempts to
retrieve the JWKS (JSON Web Key Set) from the external authentication provider.
JWKS retrieval uses an exponential backoff algorithm with an initial wait based
on the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double
in wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.retry.backoff.ms
-----------------------------------------------

The (optional) value in milliseconds for the initial wait between JWKS (JSON
Web Key Set) retrieval attempts from the external authentication provider. JWKS
retrieval uses an exponential backoff algorithm with an initial wait based on
the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double in
wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 100
Valid Values:
Importance: low


sasl.oauthbearer.scope.claim.name
---------------------------------

The OAuth claim for the scope is often named scope, but this (optional)
setting can provide a different name to use for the scope included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: scope
Valid Values:
Importance: low


sasl.oauthbearer.sub.claim.name
-------------------------------

The OAuth claim for the subject is often named sub, but this (optional)
setting can provide a different name to use for the subject included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: sub
Valid Values:
Importance: low


scheduled.rebalance.max.delay.ms
--------------------------------

The maximum delay that is scheduled in order to wait for the return of one or
more departed workers before rebalancing and reassigning their connectors and
tasks to the group. During this period the connectors and tasks of the departed
workers remain unassigned

Type: int
Default: 300000 (5 minutes)
Valid Values: [0,...,2147483647]
Importance: low


socket.connection.setup.timeout.max.ms
--------------------------------------

The maximum amount of time the client will wait for the socket connection to be
established. The connection setup timeout will increase exponentially for each
consecutive connection failure up to this maximum. To avoid connection storms,
a randomization factor of 0.2 will be applied to the timeout resulting in a
random range between 20% below and 20% above the computed value.

Type: long
Default: 30000 (30 seconds)
Valid Values: [0,...]
Importance: low


socket.connection.setup.timeout.ms
----------------------------------

The amount of time the client will wait for the socket connection to be
established. If the connection is not built before the timeout elapses, clients
will close the socket channel. This value is the initial backoff value and will
increase exponentially for each consecutive connection failure, up to the
socket.connection.setup.timeout.max.ms value.

Type: long
Default: 10000 (10 seconds)
Valid Values: [0,...]
Importance: low


ssl.cipher.suites
-----------------

A list of cipher suites. This is a named combination of authentication,
encryption, MAC and key exchange algorithm used to negotiate the security
settings for a network connection using TLS or SSL network protocol. By default
all the available cipher suites are supported.

Type: list
Default: null
Valid Values:
Importance: low


ssl.client.auth
---------------

Configures kafka broker to request client authentication. The following
settings are common: <ul> <li>ssl.client.auth=required If set to required
client authentication is required. <li>ssl.client.auth=requested This means
client authentication is optional. unlike required, if this option is set
client can choose not to provide authentication information about itself
<li>ssl.client.auth=none This means client authentication is not needed.</ul>

Type: string
Default: none
Valid Values: [required, requested, none]
Importance: low


ssl.endpoint.identification.algorithm
-------------------------------------

The endpoint identification algorithm to validate server hostname using server
certificate.

Type: string
Default: https
Valid Values:
Importance: low


ssl.engine.factory.class
------------------------

The class of type org.apache.kafka.common.security.auth.SslEngineFactory to
provide SSLEngine objects. Default value is
org.apache.kafka.common.security.ssl.DefaultSslEngineFactory. Alternatively,
setting this to
org.apache.kafka.common.security.ssl.CommonNameLoggingSslEngineFactory will log
the common name of expired SSL certificates used by clients to authenticate at
any of the brokers with log level INFO. Note that this will cause a tiny delay
during establishment of new connections from mTLS clients to brokers due to the
extra code for examining the certificate chain provided by the client. Note
further that the implementation uses a custom truststore based on the standard
Java truststore and thus might be considered a security risk due to not being
as mature as the standard one.

Type: class
Default: null
Valid Values:
Importance: low


ssl.keymanager.algorithm
------------------------

The algorithm used by key manager factory for SSL connections. Default value is
the key manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: SunX509
Valid Values:
Importance: low


ssl.secure.random.implementation
--------------------------------

The SecureRandom PRNG implementation to use for SSL cryptography operations.

Type: string
Default: null
Valid Values:
Importance: low


ssl.trustmanager.algorithm
--------------------------

The algorithm used by trust manager factory for SSL connections. Default value
is the trust manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: PKIX
Valid Values:
Importance: low


status.storage.partitions
-------------------------

The number of partitions used when creating the status storage topic

Type: int
Default: 5
Valid Values: Positive number, or -1 to use the broker's default
Importance: low


status.storage.replication.factor
---------------------------------

Replication factor used when creating the status storage topic

Type: short
Default: 3
Valid Values: Positive number not larger than the number of brokers in the Kafka cluster, or -1 to use the broker's default
Importance: low


task.shutdown.graceful.timeout.ms
---------------------------------

Amount of time to wait for tasks to shutdown gracefully. This is the total
amount of time, not per task. All task have shutdown triggered, then they are
waited on sequentially.

Type: long
Default: 5000 (5 seconds)
Valid Values:
Importance: low


topic.creation.enable
---------------------

Whether to allow automatic creation of topics used by source connectors, when
source connectors are configured with `topic.creation.` properties. Each task
will use an admin client to create its topics and will not depend on the Kafka
brokers to create topics automatically.

Type: boolean
Default: true
Valid Values:
Importance: low


topic.tracking.allow.reset
--------------------------

If set to true, it allows user requests to reset the set of active topics per
connector.

Type: boolean
Default: true
Valid Values:
Importance: low


topic.tracking.enable
---------------------

Enable tracking the set of active topics per connector during runtime.

Type: boolean
Default: true
Valid Values:
Importance: low


connector.class
---------------

Name or alias of the class for this connector. Must be a subclass of
org.apache.kafka.connect.connector.Connector. If the connector is
org.apache.kafka.connect.file.FileStreamSinkConnector, you can either specify
this full name, or use FileStreamSink or FileStreamSinkConnector to
make the configuration a bit shorter

Type: string
Default:
Valid Values:
Importance: high


tasks.max
---------

Maximum number of tasks to use for this connector.

Type: int
Default: 1
Valid Values: [1,...]
Importance: high


tasks.max.enforce
-----------------

(Deprecated) Whether to enforce that the tasks.max property is respected by the
connector. By default, connectors that generate too many tasks will fail, and
existing sets of tasks that exceed the tasks.max property will also be failed.
If this property is set to false, then connectors will be allowed to generate
more than the maximum number of tasks, and existing sets of tasks that exceed
the tasks.max property will be allowed to run. This property is deprecated and
will be removed in an upcoming major release.

Type: boolean
Default: true
Valid Values:
Importance: low


key.converter
-------------

Converter class used to convert between Kafka Connect format and the serialized
form that is written to Kafka. This controls the format of the keys in messages
written to or read from Kafka, and since this is independent of connectors it
allows any connector to work with any serialization format. Examples of common
formats include JSON and Avro.

Type: class
Default: null
Valid Values: A concrete subclass of org.apache.kafka.connect.storage.Converter, A class with a public, no-argument constructor
Importance: low


value.converter
---------------

Converter class used to convert between Kafka Connect format and the serialized
form that is written to Kafka. This controls the format of the values in
messages written to or read from Kafka, and since this is independent of
connectors it allows any connector to work with any serialization format.
Examples of common formats include JSON and Avro.

Type: class
Default: null
Valid Values: A concrete subclass of org.apache.kafka.connect.storage.Converter, A class with a public, no-argument constructor
Importance: low


header.converter
----------------

HeaderConverter class used to convert between Kafka Connect format and the
serialized form that is written to Kafka. This controls the format of the
header values in messages written to or read from Kafka, and since this is
independent of connectors it allows any connector to work with any
serialization format. Examples of common formats include JSON and Avro. By
default, the SimpleHeaderConverter is used to serialize header values to
strings and deserialize them by inferring the schemas.

Type: class
Default: null
Valid Values: A concrete subclass of org.apache.kafka.connect.storage.HeaderConverter, A class with a public, no-argument constructor
Importance: low


config.action.reload
--------------------

The action that Connect should take on the connector when changes in external
configuration providers result in a change in the connector's configuration
properties. A value of 'none' indicates that Connect will do nothing. A value
of 'restart' indicates that Connect should restart/reload the connector with
the updated configuration properties.The restart may actually be scheduled in
the future if the external configuration provider indicates that a
configuration value will expire in the future.

Type: string
Default: restart
Valid Values: [none, restart]
Importance: low


transforms
----------

Aliases for the transformations to be applied to records.

Type: list
Default:
Valid Values: non-null string, unique transformation aliases
Importance: low


predicates
----------

Aliases for the predicates used by transformations.

Type: list
Default:
Valid Values: non-null string, unique predicate aliases
Importance: low


errors.retry.timeout
--------------------

The maximum duration in milliseconds that a failed operation will be
reattempted. The default is 0, which means no retries will be attempted. Use -1
for infinite retries.

Type: long
Default: 0
Valid Values:
Importance: medium


errors.retry.delay.max.ms
-------------------------

The maximum duration in milliseconds between consecutive retry attempts. Jitter
will be added to the delay once this limit is reached to prevent thundering
herd issues.

Type: long
Default: 60000 (1 minute)
Valid Values:
Importance: medium


errors.tolerance
----------------

Behavior for tolerating errors during connector operation. 'none' is the
default value and signals that any error will result in an immediate connector
task failure; 'all' changes the behavior to skip over problematic records.

Type: string
Default: none
Valid Values: [none, all]
Importance: medium


errors.log.enable
-----------------

If true, write each error and the details of the failed operation and
problematic record to the Connect application log. This is 'false' by default,
so that only errors that are not tolerated are reported.

Type: boolean
Default: false
Valid Values:
Importance: medium


errors.log.include.messages
---------------------------

Whether to include in the log the Connect record that resulted in a failure.
For sink records, the topic, partition, offset, and timestamp will be logged.
For source records, the key and value (and their schemas), all headers, and the
timestamp, Kafka topic, Kafka partition, source partition, and source offset
will be logged. This is 'false' by default, which will prevent record keys,
values, and headers from being written to log files.

Type: boolean
Default: false
Valid Values:
Importance: medium


topic.creation.groups
---------------------

Groups of configurations for topics created by source connectors

Type: list
Default:
Valid Values: non-null string, unique topic creation groups
Importance: low


exactly.once.support
--------------------

Permitted values are requested, required. If set to required, forces a
preflight check for the connector to ensure that it can provide exactly-once
semantics with the given configuration. Some connectors may be capable of
providing exactly-once semantics but not signal to Connect that they support
this; in that case, documentation for the connector should be consulted
carefully before creating it, and the value for this property should be set to
requested. Additionally, if the value is set to required but the worker
that performs preflight validation does not have exactly-once support enabled
for source connectors, requests to create or validate the connector will fail.

Type: string
Default: requested
Valid Values: (case insensitive) [REQUIRED, REQUESTED]
Importance: medium


transaction.boundary
--------------------

Permitted values are: poll, interval, connector. If set to 'poll', a new
producer transaction will be started and committed for every batch of records
that each task from this connector provides to Connect. If set to 'connector',
relies on connector-defined transaction boundaries; note that not all
connectors are capable of defining their own transaction boundaries, and in
that case, attempts to instantiate a connector with this value will fail.
Finally, if set to 'interval', commits transactions only after a user-defined
time interval has passed.

Type: string
Default: poll
Valid Values: (case insensitive) [INTERVAL, POLL, CONNECTOR]
Importance: medium


transaction.boundary.interval.ms
--------------------------------

If 'transaction.boundary' is set to 'interval', determines the interval for
producer transaction commits by connector tasks. If unset, defaults to the
value of the worker-level 'offset.flush.interval.ms' property. It has no effect
if a different transaction.boundary is specified.

Type: long
Default: null
Valid Values: [0,...]
Importance: low


offsets.storage.topic
---------------------

The name of a separate offsets topic to use for this connector. If empty or not
specified, the worker’s global offsets topic name will be used. If specified,
the offsets topic will be created if it does not already exist on the Kafka
cluster targeted by this connector (which may be different from the one used
for the worker's global offsets topic if the bootstrap.servers property of the
    connector's producer has been overridden from the worker's). Only
    applicable in distributed mode; in standalone mode, setting this property
    will have no effect.

Type: string
Default: null
Valid Values: non-empty string
Importance: low


connector.class
---------------

Name or alias of the class for this connector. Must be a subclass of
org.apache.kafka.connect.connector.Connector. If the connector is
org.apache.kafka.connect.file.FileStreamSinkConnector, you can either specify
this full name, or use FileStreamSink or FileStreamSinkConnector to
make the configuration a bit shorter

Type: string
Default:
Valid Values:
Importance: high


tasks.max
---------

Maximum number of tasks to use for this connector.

Type: int
Default: 1
Valid Values: [1,...]
Importance: high


topics
------

List of topics to consume, separated by commas

Type: list
Default:
Valid Values:
Importance: high


topics.regex
------------

Regular expression giving topics to consume. Under the hood, the regex is
compiled to a java.util.regex.Pattern. Only one of topics or topics.regex
should be specified.

Type: string
Default:
Valid Values: valid regex
Importance: high


tasks.max.enforce
-----------------

(Deprecated) Whether to enforce that the tasks.max property is respected by the
connector. By default, connectors that generate too many tasks will fail, and
existing sets of tasks that exceed the tasks.max property will also be failed.
If this property is set to false, then connectors will be allowed to generate
more than the maximum number of tasks, and existing sets of tasks that exceed
the tasks.max property will be allowed to run. This property is deprecated and
will be removed in an upcoming major release.

Type: boolean
Default: true
Valid Values:
Importance: low


key.converter
-------------

Converter class used to convert between Kafka Connect format and the serialized
form that is written to Kafka. This controls the format of the keys in messages
written to or read from Kafka, and since this is independent of connectors it
allows any connector to work with any serialization format. Examples of common
formats include JSON and Avro.

Type: class
Default: null
Valid Values: A concrete subclass of org.apache.kafka.connect.storage.Converter, A class with a public, no-argument constructor
Importance: low


value.converter
---------------

Converter class used to convert between Kafka Connect format and the serialized
form that is written to Kafka. This controls the format of the values in
messages written to or read from Kafka, and since this is independent of
connectors it allows any connector to work with any serialization format.
Examples of common formats include JSON and Avro.

Type: class
Default: null
Valid Values: A concrete subclass of org.apache.kafka.connect.storage.Converter, A class with a public, no-argument constructor
Importance: low


header.converter
----------------

HeaderConverter class used to convert between Kafka Connect format and the
serialized form that is written to Kafka. This controls the format of the
header values in messages written to or read from Kafka, and since this is
independent of connectors it allows any connector to work with any
serialization format. Examples of common formats include JSON and Avro. By
default, the SimpleHeaderConverter is used to serialize header values to
strings and deserialize them by inferring the schemas.

Type: class
Default: null
Valid Values: A concrete subclass of org.apache.kafka.connect.storage.HeaderConverter, A class with a public, no-argument constructor
Importance: low


config.action.reload
--------------------

The action that Connect should take on the connector when changes in external
configuration providers result in a change in the connector's configuration
properties. A value of 'none' indicates that Connect will do nothing. A value
of 'restart' indicates that Connect should restart/reload the connector with
the updated configuration properties.The restart may actually be scheduled in
the future if the external configuration provider indicates that a
configuration value will expire in the future.

Type: string
Default: restart
Valid Values: [none, restart]
Importance: low


transforms
----------

Aliases for the transformations to be applied to records.

Type: list
Default:
Valid Values: non-null string, unique transformation aliases
Importance: low


predicates
----------

Aliases for the predicates used by transformations.

Type: list
Default:
Valid Values: non-null string, unique predicate aliases
Importance: low


errors.retry.timeout
--------------------

The maximum duration in milliseconds that a failed operation will be
reattempted. The default is 0, which means no retries will be attempted. Use -1
for infinite retries.

Type: long
Default: 0
Valid Values:
Importance: medium


errors.retry.delay.max.ms
-------------------------

The maximum duration in milliseconds between consecutive retry attempts. Jitter
will be added to the delay once this limit is reached to prevent thundering
herd issues.

Type: long
Default: 60000 (1 minute)
Valid Values:
Importance: medium


errors.tolerance
----------------

Behavior for tolerating errors during connector operation. 'none' is the
default value and signals that any error will result in an immediate connector
task failure; 'all' changes the behavior to skip over problematic records.

Type: string
Default: none
Valid Values: [none, all]
Importance: medium


errors.log.enable
-----------------

If true, write each error and the details of the failed operation and
problematic record to the Connect application log. This is 'false' by default,
so that only errors that are not tolerated are reported.

Type: boolean
Default: false
Valid Values:
Importance: medium


errors.log.include.messages
---------------------------

Whether to include in the log the Connect record that resulted in a failure.
For sink records, the topic, partition, offset, and timestamp will be logged.
For source records, the key and value (and their schemas), all headers, and the
timestamp, Kafka topic, Kafka partition, source partition, and source offset
will be logged. This is 'false' by default, which will prevent record keys,
values, and headers from being written to log files.

Type: boolean
Default: false
Valid Values:
Importance: medium


errors.deadletterqueue.topic.name
---------------------------------

The name of the topic to be used as the dead letter queue (DLQ) for messages
that result in an error when processed by this sink connector, or its
transformations or converters. The topic name is blank by default, which means
that no messages are to be recorded in the DLQ.

Type: string
Default:
Valid Values:
Importance: medium


errors.deadletterqueue.topic.replication.factor
-----------------------------------------------

Replication factor used to create the dead letter queue topic when it doesn't
already exist.

Type: short
Default: 3
Valid Values:
Importance: medium


errors.deadletterqueue.context.headers.enable
---------------------------------------------

If true, add headers containing error context to the messages written to the
dead letter queue. To avoid clashing with headers from the original record, all
error context header keys, all error context header keys will start with
__connect.errors.

Type: boolean
Default: false
Valid Values:
Importance: medium


bootstrap.servers
-----------------

A list of host/port pairs to use for establishing the initial connection to the
Kafka cluster. The client will make use of all servers irrespective of which
servers are specified here for bootstrapping&mdash;this list only impacts the
initial hosts used to discover the full set of servers. This list should be in
the form host1:port1,host2:port2,.... Since these servers are just used for
the initial connection to discover the full cluster membership (which may
change dynamically), this list need not contain the full set of servers (you
may want more than one, though, in case a server is down).

Type: list
Default:
Valid Values:
Importance: high


num.standby.replicas
--------------------

The number of standby replicas for each task.

Type: int
Default: 0
Valid Values:
Importance: high


state.dir
---------

Directory location for state store. This path must be unique for each streams
instance sharing the same underlying filesystem. Note that if not configured,
then the default location will be different in each environment as it is
computed using System.getProperty(java.io.tmpdir)

Type: string
Default: ${java.io.tmpdir}
Valid Values:
Importance: high


acceptable.recovery.lag
-----------------------

The maximum acceptable lag (number of offsets to catch up) for a client to be
considered caught-up enough to receive an active task assignment. Upon
assignment, it will still restore the rest of the changelog before processing.
To avoid a pause in processing during rebalances, this config should correspond
to a recovery time of well under a minute for a given workload. Must be at
least 0.

Type: long
Default: 10000
Valid Values: [0,...]
Importance: medium


cache.max.bytes.buffering
-------------------------

Maximum number of memory bytes to be used for buffering across all threads

Type: long
Default: 10485760
Valid Values: [0,...]
Importance: medium


client.id
---------

An ID prefix string used for the client IDs of internal (main, restore, and
global) consumers , producers, and admin clients with pattern
<client.id>-[Global]StreamThread[-<threadSequenceNumber>]-<consumer|producer|restore-consumer|global-consumer>.

Type: string
Default: <application.id&gt-<random-UUID&gt
Valid Values:
Importance: medium


default.deserialization.exception.handler
-----------------------------------------

Exception handling class that implements the
org.apache.kafka.streams.errors.DeserializationExceptionHandler interface.

Type: class
Default: org.apache.kafka.streams.errors.LogAndFailExceptionHandler
Valid Values:
Importance: medium


default.key.serde
-----------------

Default serializer / deserializer class for key that implements the
org.apache.kafka.common.serialization.Serde interface. Note when windowed
serde class is used, one needs to set the inner serde class that implements the
org.apache.kafka.common.serialization.Serde interface via
'default.windowed.key.serde.inner' or 'default.windowed.value.serde.inner' as
well

Type: class
Default: null
Valid Values:
Importance: medium


default.list.key.serde.inner
----------------------------

Default inner class of list serde for key that implements the
org.apache.kafka.common.serialization.Serde interface. This configuration
will be read if and only if default.key.serde configuration is set to
org.apache.kafka.common.serialization.Serdes.ListSerde

Type: class
Default: null
Valid Values:
Importance: medium


default.list.key.serde.type
---------------------------

Default class for key that implements the java.util.List interface. This
configuration will be read if and only if default.key.serde configuration is
set to org.apache.kafka.common.serialization.Serdes.ListSerde Note when list
serde class is used, one needs to set the inner serde class that implements the
org.apache.kafka.common.serialization.Serde interface via
'default.list.key.serde.inner'

Type: class
Default: null
Valid Values:
Importance: medium


default.list.value.serde.inner
------------------------------

Default inner class of list serde for value that implements the
org.apache.kafka.common.serialization.Serde interface. This configuration
will be read if and only if default.value.serde configuration is set to
org.apache.kafka.common.serialization.Serdes.ListSerde

Type: class
Default: null
Valid Values:
Importance: medium


default.list.value.serde.type
-----------------------------

Default class for value that implements the java.util.List interface. This
configuration will be read if and only if default.value.serde configuration
is set to org.apache.kafka.common.serialization.Serdes.ListSerde Note when
list serde class is used, one needs to set the inner serde class that
implements the org.apache.kafka.common.serialization.Serde interface via
'default.list.value.serde.inner'

Type: class
Default: null
Valid Values:
Importance: medium


default.production.exception.handler
------------------------------------

Exception handling class that implements the
org.apache.kafka.streams.errors.ProductionExceptionHandler interface.

Type: class
Default: org.apache.kafka.streams.errors.DefaultProductionExceptionHandler
Valid Values:
Importance: medium


default.timestamp.extractor
---------------------------

Default timestamp extractor class that implements the
org.apache.kafka.streams.processor.TimestampExtractor interface.

Type: class
Default: org.apache.kafka.streams.processor.FailOnInvalidTimestamp
Valid Values:
Importance: medium


default.value.serde
-------------------

Default serializer / deserializer class for value that implements the
org.apache.kafka.common.serialization.Serde interface. Note when windowed
serde class is used, one needs to set the inner serde class that implements the
org.apache.kafka.common.serialization.Serde interface via
'default.windowed.key.serde.inner' or 'default.windowed.value.serde.inner' as
well

Type: class
Default: null
Valid Values:
Importance: medium


max.task.idle.ms
----------------

This config controls whether joins and merges may produce out-of-order results.
The config value is the maximum amount of time in milliseconds a stream task
will stay idle when it is fully caught up on some (but not all) input
partitions to wait for producers to send additional records and avoid potential
out-of-order record processing across multiple input streams. The default
(zero) does not wait for producers to send more records, but it does wait to
fetch data that is already present on the brokers. This default means that for
records that are already present on the brokers, Streams will process them in
timestamp order. Set to -1 to disable idling entirely and process any locally
available data, even though doing so may produce out-of-order processing.

Type: long
Default: 0
Valid Values:
Importance: medium


max.warmup.replicas
-------------------

The maximum number of warmup replicas (extra standbys beyond the configured
num.standbys) that can be assigned at once for the purpose of keeping the task
available on one instance while it is warming up on another instance it has
been reassigned to. Used to throttle how much extra broker traffic and cluster
state can be used for high availability. Must be at least 1.Note that one
warmup replica corresponds to one Stream Task. Furthermore, note that each
warmup replica can only be promoted to an active task during a rebalance
(normally during a so-called probing rebalance, which occur at a frequency
specified by the `probing.rebalance.interval.ms` config). This means that the
maximum rate at which active tasks can be migrated from one Kafka Streams
Instance to another instance can be determined by (`max.warmup.replicas` /
`probing.rebalance.interval.ms`).

Type: int
Default: 2
Valid Values: [1,...]
Importance: medium


num.stream.threads
------------------

The number of threads to execute stream processing.

Type: int
Default: 1
Valid Values:
Importance: medium


processing.guarantee
--------------------

The processing guarantee that should be used. Possible values are
at_least_once (default) and exactly_once_v2 (requires brokers version
2.5 or higher). Deprecated options are exactly_once (requires brokers
version 0.11.0 or higher) and exactly_once_beta (requires brokers version
2.5 or higher). Note that exactly-once processing requires a cluster of at
least three brokers by default what is the recommended setting for production;
for development you can change this, by adjusting broker setting
    transaction.state.log.replication.factor and
    transaction.state.log.min.isr.

Type: string
Default: at_least_once
Valid Values: [at_least_once, exactly_once, exactly_once_beta, exactly_once_v2]
Importance: medium


rack.aware.assignment.non_overlap_cost
----------------------------------------

Cost associated with moving tasks from existing assignment. This config and
rack.aware.assignment.traffic_cost controls whether the optimization
algorithm favors minimizing cross rack traffic or minimize the movement of
tasks in existing assignment. If set a larger value
org.apache.kafka.streams.processor.internals.assignment.RackAwareTaskAssignor
will optimize to maintain the existing assignment. The default value is null
which means it will use default non_overlap cost values in different
assignors.

Type: int
Default: null
Valid Values:
Importance: medium


rack.aware.assignment.strategy
------------------------------

The strategy we use for rack aware assignment. Rack aware assignment will take
client.rack and racks of TopicPartition into account when assigning tasks
to minimize cross rack traffic. Valid settings are : none (default), which
will disable rack aware assignment; min_traffic, which will compute minimum
cross rack traffic assignment; balance_subtopology, which will compute
minimum cross rack traffic and try to balance the tasks of same subtopolgies
across different clients

Type: string
Default: none
Valid Values: [none, min_traffic, balance_subtopology]
Importance: medium


rack.aware.assignment.tags
--------------------------

List of client tag keys used to distribute standby replicas across Kafka
Streams instances. When configured, Kafka Streams will make a best-effort to
distribute the standby tasks over each client tag dimension.

Type: list
Default:
Valid Values: List containing maximum of 5 elements
Importance: medium


rack.aware.assignment.traffic_cost
-----------------------------------

Cost associated with cross rack traffic. This config and
rack.aware.assignment.non_overlap_cost controls whether the optimization
algorithm favors minimizing cross rack traffic or minimize the movement of
tasks in existing assignment. If set a larger value
org.apache.kafka.streams.processor.internals.assignment.RackAwareTaskAssignor
will optimize for minimizing cross rack traffic. The default value is null
which means it will use default traffic cost values in different assignors.

Type: int
Default: null
Valid Values:
Importance: medium


replication.factor
------------------

The replication factor for change log topics and repartition topics created by
the stream processing application. The default of -1 (meaning: use broker
default replication factor) requires broker version 2.4 or newer

Type: int
Default: -1
Valid Values:
Importance: medium


security.protocol
-----------------

Protocol used to communicate with brokers. Valid values are: PLAINTEXT, SSL,
SASL_PLAINTEXT, SASL_SSL.

Type: string
Default: PLAINTEXT
Valid Values: (case insensitive) [SASL_SSL, PLAINTEXT, SSL, SASL_PLAINTEXT]
Importance: medium


statestore.cache.max.bytes
--------------------------

Maximum number of memory bytes to be used for statestore cache across all
threads

Type: long
Default: 10485760 (10 mebibytes)
Valid Values: [0,...]
Importance: medium


task.assignor.class
-------------------

A task assignor class or class name implementing the
org.apache.kafka.streams.processor.assignment.TaskAssignor interface.
Defaults to the HighAvailabilityTaskAssignor class.

Type: string
Default: null
Valid Values:
Importance: medium


task.timeout.ms
---------------

The maximum amount of time in milliseconds a task might stall due to internal
errors and retries until an error is raised. For a timeout of 0ms, a task would
raise an error for the first internal error. For any timeout larger than 0ms, a
task will retry at least once before an error is raised.

Type: long
Default: 300000 (5 minutes)
Valid Values: [0,...]
Importance: medium


topology.optimization
---------------------

A configuration telling Kafka Streams if it should optimize the topology and
what optimizations to apply. Acceptable values are: +NO_OPTIMIZATION+,
+OPTIMIZE+, or a comma separated list of specific optimizations:
(+REUSE_KTABLE_SOURCE_TOPICS+, +MERGE_REPARTITION_TOPICS+ +
SINGLE_STORE_SELF_JOIN+).NO_OPTIMIZATION by default.

Type: string
Default: none
Valid Values: org.apache.kafka.streams.StreamsConfig$$Lambda$20/0x0000000800c0cf18@b1bc7ed
Importance: medium


application.server
------------------

A host:port pair pointing to a user-defined endpoint that can be used for state
store discovery and interactive queries on this KafkaStreams instance.

Type: string
Default:
Valid Values:
Importance: low


auto.include.jmx.reporter
-------------------------

Deprecated. Whether to automatically include JmxReporter even if it's not
listed in metric.reporters. This configuration will be removed in Kafka 4.0,
users should instead include org.apache.kafka.common.metrics.JmxReporter in
metric.reporters in order to enable the JmxReporter.

Type: boolean
Default: true
Valid Values:
Importance: low


buffered.records.per.partition
------------------------------

Maximum number of records to buffer per partition.

Type: int
Default: 1000
Valid Values:
Importance: low


built.in.metrics.version
------------------------

Version of the built-in metrics to use.

Type: string
Default: latest
Valid Values: [latest]
Importance: low


commit.interval.ms
------------------

The frequency in milliseconds with which to commit processing progress. For
at-least-once processing, committing means to save the position (ie, offsets)
of the processor. For exactly-once processing, it means to commit the
transaction which includes to save the position and to make the committed data
in the output topic visible to consumers with isolation level read_committed.
(Note, if processing.guarantee is set to exactly_once_v2,
exactly_once,the default value is 100, otherwise the default value is
30000.

Type: long
Default: 30000 (30 seconds)
Valid Values: [0,...]
Importance: low


connections.max.idle.ms
-----------------------

Close idle connections after the number of milliseconds specified by this
config.

Type: long
Default: 540000 (9 minutes)
Valid Values:
Importance: low


default.client.supplier
-----------------------

Client supplier class that implements the
org.apache.kafka.streams.KafkaClientSupplier interface.

Type: class
Default: org.apache.kafka.streams.processor.internals.DefaultKafkaClientSupplier
Valid Values:
Importance: low


default.dsl.store
-----------------

The default state store type used by DSL operators.

Type: string
Default: rocksDB
Valid Values: [rocksDB, in_memory]
Importance: low


dsl.store.suppliers.class
-------------------------

Defines which store implementations to plug in to DSL operators. Must implement
the org.apache.kafka.streams.state.DslStoreSuppliers interface.

Type: class
Default: org.apache.kafka.streams.state.BuiltInDslStoreSuppliers$RocksDBDslStoreSuppliers
Valid Values:
Importance: low


enable.metrics.push
-------------------

Whether to enable pushing of internal client metrics for (main, restore, and
global) consumers, producers, and admin clients. The cluster must have a client
metrics subscription which corresponds to a client.

Type: boolean
Default: true
Valid Values:
Importance: low


metadata.max.age.ms
-------------------

The period of time in milliseconds after which we force a refresh of metadata
even if we haven't seen any partition leadership changes to proactively
discover any new brokers or partitions.

Type: long
Default: 300000 (5 minutes)
Valid Values: [0,...]
Importance: low


metric.reporters
----------------

A list of classes to use as metrics reporters. Implementing the
org.apache.kafka.common.metrics.MetricsReporter interface allows plugging in
classes that will be notified of new metric creation. The JmxReporter is always
included to register JMX statistics.

Type: list
Default:
Valid Values:
Importance: low


metrics.num.samples
-------------------

The number of samples maintained to compute metrics.

Type: int
Default: 2
Valid Values: [1,...]
Importance: low


metrics.recording.level
-----------------------

The highest recording level for metrics.

Type: string
Default: INFO
Valid Values: [INFO, DEBUG, TRACE]
Importance: low


metrics.sample.window.ms
------------------------

The window of time a metrics sample is computed over.

Type: long
Default: 30000 (30 seconds)
Valid Values: [0,...]
Importance: low


poll.ms
-------

The amount of time in milliseconds to block waiting for input.

Type: long
Default: 100
Valid Values:
Importance: low


probing.rebalance.interval.ms
-----------------------------

The maximum time in milliseconds to wait before triggering a rebalance to probe
for warmup replicas that have finished warming up and are ready to become
    active. Probing rebalances will continue to be triggered until the
    assignment is balanced. Must be at least 1 minute.

Type: long
Default: 600000 (10 minutes)
Valid Values: [60000,...]
Importance: low


receive.buffer.bytes
--------------------

The size of the TCP receive buffer (SO_RCVBUF) to use when reading data. If
the value is -1, the OS default will be used.

Type: int
Default: 32768 (32 kibibytes)
Valid Values: [-1,...]
Importance: low


reconnect.backoff.max.ms
------------------------

The maximum amount of time in milliseconds to wait when reconnecting to a
broker that has repeatedly failed to connect. If provided, the backoff per host
will increase exponentially for each consecutive connection failure, up to this
maximum. After calculating the backoff increase, 20% random jitter is added to
avoid connection storms.

Type: long
Default: 1000 (1 second)
Valid Values: [0,...]
Importance: low


reconnect.backoff.ms
--------------------

The base amount of time to wait before attempting to reconnect to a given host.
This avoids repeatedly connecting to a host in a tight loop. This backoff
applies to all connection attempts by the client to a broker. This value is the
initial backoff value and will increase exponentially for each consecutive
connection failure, up to the reconnect.backoff.max.ms value.

Type: long
Default: 50
Valid Values: [0,...]
Importance: low


repartition.purge.interval.ms
-----------------------------

The frequency in milliseconds with which to delete fully consumed records from
repartition topics. Purging will occur after at least this value since the last
purge, but may be delayed until later. (Note, unlike commit.interval.ms, the
default for this value remains unchanged when processing.guarantee is set to
exactly_once_v2).

Type: long
Default: 30000 (30 seconds)
Valid Values: [0,...]
Importance: low


request.timeout.ms
------------------

The configuration controls the maximum amount of time the client will wait for
the response of a request. If the response is not received before the timeout
elapses the client will resend the request if necessary or fail the request if
retries are exhausted.

Type: int
Default: 40000 (40 seconds)
Valid Values: [0,...]
Importance: low


retries
-------

Setting a value greater than zero will cause the client to resend any request
that fails with a potentially transient error. It is recommended to set the
value to either zero or `MAX_VALUE` and use corresponding timeout parameters
to control how long a client should retry a request.

Type: int
Default: 0
Valid Values: [0,...,2147483647]
Importance: low


retry.backoff.ms
----------------

The amount of time to wait before attempting to retry a failed request to a
given topic partition. This avoids repeatedly sending requests in a tight loop
under some failure scenarios. This value is the initial backoff value and will
increase exponentially for each failed request, up to the
retry.backoff.max.ms value.

Type: long
Default: 100
Valid Values: [0,...]
Importance: low


rocksdb.config.setter
---------------------

A Rocks DB config setter class or class name that implements the
org.apache.kafka.streams.state.RocksDBConfigSetter interface

Type: class
Default: null
Valid Values:
Importance: low


send.buffer.bytes
-----------------

The size of the TCP send buffer (SO_SNDBUF) to use when sending data. If the
value is -1, the OS default will be used.

Type: int
Default: 131072 (128 kibibytes)
Valid Values: [-1,...]
Importance: low


state.cleanup.delay.ms
----------------------

The amount of time in milliseconds to wait before deleting state when a
partition has migrated. Only state directories that have not been modified for
at least state.cleanup.delay.ms will be removed

Type: long
Default: 600000 (10 minutes)
Valid Values:
Importance: low


upgrade.from
------------

Allows upgrading in a backward compatible way. This is needed when upgrading
from [0.10.0, 1.1] to 2.0+, or when upgrading from [2.0, 2.3] to 2.4+. When
upgrading from 3.3 to a newer version it is not required to specify this
config. Default is `null`. Accepted values are 0.10.0, 0.10.1,
0.10.2, 0.11.0, 1.0, 1.1, 2.0, 2.1, 2.2, 2.3,
2.4, 2.5, 2.6, 2.7, 2.8, 3.0, 3.1, 3.2,
3.3, 3.4, 3.5, 3.6, 3.7(for upgrading from the corresponding
old version).

Type: string
Default: null
Valid Values: [null, 0.10.0, 0.10.1, 0.10.2, 0.11.0, 1.0, 1.1, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7]
Importance: low


window.size.ms
--------------

Sets window size for the deserializer in order to calculate window end times.

Type: long
Default: null
Valid Values:
Importance: low


windowed.inner.class.serde
--------------------------

 Default serializer / deserializer for the inner class of a windowed record.
 Must implement the org.apache.kafka.common.serialization.Serde interface.
 Note that setting this config in KafkaStreams application would result in an
 error as it is meant to be used only from Plain consumer client.

Type: string
Default: null
Valid Values:
Importance: low


windowstore.changelog.additional.retention.ms
---------------------------------------------

Added to a windows maintainMs to ensure data is not deleted from the log
prematurely. Allows for clock drift. Default is 1 day

Type: long
Default: 86400000 (1 day)
Valid Values:
Importance: low


bootstrap.servers
-----------------

A list of host/port pairs to use for establishing the initial connection to the
Kafka cluster. The client will make use of all servers irrespective of which
servers are specified here for bootstrapping&mdash;this list only impacts the
initial hosts used to discover the full set of servers. This list should be in
the form host1:port1,host2:port2,.... Since these servers are just used for
the initial connection to discover the full cluster membership (which may
change dynamically), this list need not contain the full set of servers (you
may want more than one, though, in case a server is down).

Type: list
Default:
Valid Values:
Importance: high


ssl.key.password
----------------

The password of the private key in the key store file or the PEM key specified
in 'ssl.keystore.key'.

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.certificate.chain
------------------------------

Certificate chain in the format specified by 'ssl.keystore.type'. Default SSL
engine factory supports only PEM format with a list of X.509 certificates

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.key
----------------

Private key in the format specified by 'ssl.keystore.type'. Default SSL engine
factory supports only PEM format with PKCS#8 keys. If the key is encrypted, key
password must be specified using 'ssl.key.password'

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.location
---------------------

The location of the key store file. This is optional for client and can be used
for two-way authentication for client.

Type: string
Default: null
Valid Values:
Importance: high


ssl.keystore.password
---------------------

The store password for the key store file. This is optional for client and only
needed if 'ssl.keystore.location' is configured. Key store password is not
supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: high


ssl.truststore.certificates
---------------------------

Trusted certificates in the format specified by 'ssl.truststore.type'. Default
SSL engine factory supports only PEM format with X.509 certificates.

Type: password
Default: null
Valid Values:
Importance: high


ssl.truststore.location
-----------------------

The location of the trust store file.

Type: string
Default: null
Valid Values:
Importance: high


ssl.truststore.password
-----------------------

The password for the trust store file. If a password is not set, trust store
file configured will still be used, but integrity checking is disabled. Trust
store password is not supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: high


client.dns.lookup
-----------------

Controls how the client uses DNS lookups. If set to use_all_dns_ips,
connect to each returned IP address in sequence until a successful connection
is established. After a disconnection, the next IP is used. Once all IPs have
been used once, the client resolves the IP(s) from the hostname again (both the
JVM and the OS cache DNS name lookups, however). If set to
resolve_canonical_bootstrap_servers_only, resolve each bootstrap address
into a list of canonical names. After the bootstrap phase, this behaves the
same as use_all_dns_ips.

Type: string
Default: use_all_dns_ips
Valid Values: [use_all_dns_ips, resolve_canonical_bootstrap_servers_only]
Importance: medium


client.id
---------

An id string to pass to the server when making requests. The purpose of this is
to be able to track the source of requests beyond just ip/port by allowing a
logical application name to be included in server-side request logging.

Type: string
Default:
Valid Values:
Importance: medium


connections.max.idle.ms
-----------------------

Close idle connections after the number of milliseconds specified by this
config.

Type: long
Default: 300000 (5 minutes)
Valid Values:
Importance: medium


default.api.timeout.ms
----------------------

Specifies the timeout (in milliseconds) for client APIs. This configuration is
used as the default timeout for all client operations that do not specify a
timeout parameter.

Type: int
Default: 60000 (1 minute)
Valid Values: [0,...]
Importance: medium


receive.buffer.bytes
--------------------

The size of the TCP receive buffer (SO_RCVBUF) to use when reading data. If
the value is -1, the OS default will be used.

Type: int
Default: 65536 (64 kibibytes)
Valid Values: [-1,...]
Importance: medium


request.timeout.ms
------------------

The configuration controls the maximum amount of time the client will wait for
the response of a request. If the response is not received before the timeout
elapses the client will resend the request if necessary or fail the request if
retries are exhausted.

Type: int
Default: 30000 (30 seconds)
Valid Values: [0,...]
Importance: medium


sasl.client.callback.handler.class
----------------------------------

The fully qualified name of a SASL client callback handler class that
implements the AuthenticateCallbackHandler interface.

Type: class
Default: null
Valid Values:
Importance: medium


sasl.jaas.config
----------------

JAAS login context parameters for SASL connections in the format used by JAAS
configuration files. JAAS configuration file format is described <a
href=https://docs.oracle.com/javase/8/docs/technotes/guides/security/jgss/tutorials/LoginConfigFile.html>here</a>.
The format for the value is: loginModuleClass controlFlag
(optionName=optionValue);. For brokers, the config must be prefixed with
listener prefix and SASL mechanism name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.jaas.config=com.example.ScramLoginModule
required;

Type: password
Default: null
Valid Values:
Importance: medium


sasl.kerberos.service.name
--------------------------

The Kerberos principal name that Kafka runs as. This can be defined either in
Kafka's JAAS config or in Kafka's config.

Type: string
Default: null
Valid Values:
Importance: medium


sasl.login.callback.handler.class
---------------------------------

The fully qualified name of a SASL login callback handler class that implements
the AuthenticateCallbackHandler interface. For brokers, login callback handler
config must be prefixed with listener prefix and SASL mechanism name in
lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.callback.handler.class=com.example.CustomScramLoginCallbackHandler

Type: class
Default: null
Valid Values:
Importance: medium


sasl.login.class
----------------

The fully qualified name of a class that implements the Login interface. For
brokers, login config must be prefixed with listener prefix and SASL mechanism
name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.class=com.example.CustomScramLogin

Type: class
Default: null
Valid Values:
Importance: medium


sasl.mechanism
--------------

SASL mechanism used for client connections. This may be any mechanism for which
a security provider is available. GSSAPI is the default mechanism.

Type: string
Default: GSSAPI
Valid Values:
Importance: medium


sasl.oauthbearer.jwks.endpoint.url
----------------------------------

The OAuth/OIDC provider URL from which the provider's <a
href=https://datatracker.ietf.org/doc/html/rfc7517#section-5>JWKS (JSON Web
Key Set)</a> can be retrieved. The URL can be HTTP(S)-based or file-based. If
the URL is HTTP(S)-based, the JWKS data will be retrieved from the OAuth/OIDC
provider via the configured URL on broker startup. All then-current keys will
be cached on the broker for incoming requests. If an authentication request is
received for a JWT that includes a kid header claim value that isn't yet in
the cache, the JWKS endpoint will be queried again on demand. However, the
broker polls the URL every sasl.oauthbearer.jwks.endpoint.refresh.ms
milliseconds to refresh the cache with any forthcoming keys before any JWT
requests that include them are received. If the URL is file-based, the broker
will load the JWKS file from a configured location on startup. In the event
that the JWT includes a kid header value that isn't in the JWKS file, the
broker will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: medium


sasl.oauthbearer.token.endpoint.url
-----------------------------------

The URL for the OAuth/OIDC identity provider. If the URL is HTTP(S)-based, it
is the issuer's token endpoint URL to which requests will be made to login
based on the configuration in sasl.jaas.config. If the URL is file-based, it
specifies a file containing an access token (in JWT serialized form) issued by
the OAuth/OIDC identity provider to use for authorization.

Type: string
Default: null
Valid Values:
Importance: medium


security.protocol
-----------------

Protocol used to communicate with brokers. Valid values are: PLAINTEXT, SSL,
SASL_PLAINTEXT, SASL_SSL.

Type: string
Default: PLAINTEXT
Valid Values: (case insensitive) [SASL_SSL, PLAINTEXT, SSL, SASL_PLAINTEXT]
Importance: medium


send.buffer.bytes
-----------------

The size of the TCP send buffer (SO_SNDBUF) to use when sending data. If the
value is -1, the OS default will be used.

Type: int
Default: 131072 (128 kibibytes)
Valid Values: [-1,...]
Importance: medium


socket.connection.setup.timeout.max.ms
--------------------------------------

The maximum amount of time the client will wait for the socket connection to be
established. The connection setup timeout will increase exponentially for each
consecutive connection failure up to this maximum. To avoid connection storms,
a randomization factor of 0.2 will be applied to the timeout resulting in a
random range between 20% below and 20% above the computed value.

Type: long
Default: 30000 (30 seconds)
Valid Values:
Importance: medium


socket.connection.setup.timeout.ms
----------------------------------

The amount of time the client will wait for the socket connection to be
established. If the connection is not built before the timeout elapses, clients
will close the socket channel. This value is the initial backoff value and will
increase exponentially for each consecutive connection failure, up to the
socket.connection.setup.timeout.max.ms value.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: medium


ssl.enabled.protocols
---------------------

The list of protocols enabled for SSL connections. The default is
'TLSv1.2,TLSv1.3' when running with Java 11 or newer, 'TLSv1.2' otherwise. With
the default value for Java 11, clients and servers will prefer TLSv1.3 if both
support it and fallback to TLSv1.2 otherwise (assuming both support at least
TLSv1.2). This default should be fine for most cases. Also see the config
documentation for `ssl.protocol`.

Type: list
Default: TLSv1.2,TLSv1.3
Valid Values:
Importance: medium


ssl.keystore.type
-----------------

The file format of the key store file. This is optional for client. The values
currently supported by the default `ssl.engine.factory.class` are [JKS,
PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium


ssl.protocol
------------

The SSL protocol used to generate the SSLContext. The default is 'TLSv1.3' when
running with Java 11 or newer, 'TLSv1.2' otherwise. This value should be fine
for most use cases. Allowed values in recent JVMs are 'TLSv1.2' and 'TLSv1.3'.
    'TLS', 'TLSv1.1', 'SSL', 'SSLv2' and 'SSLv3' may be supported in older
    JVMs, but their usage is discouraged due to known security vulnerabilities.
    With the default value for this config and 'ssl.enabled.protocols', clients
    will downgrade to 'TLSv1.2' if the server does not support 'TLSv1.3'. If
    this config is set to 'TLSv1.2', clients will not use 'TLSv1.3' even if it
    is one of the values in ssl.enabled.protocols and the server only supports
    'TLSv1.3'.

Type: string
Default: TLSv1.3
Valid Values:
Importance: medium


ssl.provider
------------

The name of the security provider used for SSL connections. Default value is
the default security provider of the JVM.

Type: string
Default: null
Valid Values:
Importance: medium


ssl.truststore.type
-------------------

The file format of the trust store file. The values currently supported by the
default `ssl.engine.factory.class` are [JKS, PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium


auto.include.jmx.reporter
-------------------------

Deprecated. Whether to automatically include JmxReporter even if it's not
listed in metric.reporters. This configuration will be removed in Kafka 4.0,
users should instead include org.apache.kafka.common.metrics.JmxReporter in
metric.reporters in order to enable the JmxReporter.

Type: boolean
Default: true
Valid Values:
Importance: low


enable.metrics.push
-------------------

Whether to enable pushing of client metrics to the cluster, if the cluster has
a client metrics subscription which matches this client.

Type: boolean
Default: true
Valid Values:
Importance: low


metadata.max.age.ms
-------------------

The period of time in milliseconds after which we force a refresh of metadata
even if we haven't seen any partition leadership changes to proactively
discover any new brokers or partitions.

Type: long
Default: 300000 (5 minutes)
Valid Values: [0,...]
Importance: low


metadata.recovery.strategy
--------------------------

Controls how the client recovers when none of the brokers known to it is
available. If set to none, the client fails. If set to rebootstrap, the
client repeats the bootstrap process using bootstrap.servers. Rebootstrapping
is useful when a client communicates with brokers so infrequently that the set
of brokers may change entirely before the client refreshes metadata. Metadata
recovery is triggered when all last-known brokers appear unavailable
simultaneously. Brokers appear unavailable when disconnected and no current
retry attempt is in-progress. Consider increasing reconnect.backoff.ms and
reconnect.backoff.max.ms and decreasing socket.connection.setup.timeout.ms
and socket.connection.setup.timeout.max.ms for the client.

Type: string
Default: none
Valid Values: (case insensitive) [REBOOTSTRAP, NONE]
Importance: low


metric.reporters
----------------

A list of classes to use as metrics reporters. Implementing the
org.apache.kafka.common.metrics.MetricsReporter interface allows plugging in
classes that will be notified of new metric creation. The JmxReporter is always
included to register JMX statistics.

Type: list
Default:
Valid Values:
Importance: low


metrics.num.samples
-------------------

The number of samples maintained to compute metrics.

Type: int
Default: 2
Valid Values: [1,...]
Importance: low


metrics.recording.level
-----------------------

The highest recording level for metrics.

Type: string
Default: INFO
Valid Values: [INFO, DEBUG, TRACE]
Importance: low


metrics.sample.window.ms
------------------------

The window of time a metrics sample is computed over.

Type: long
Default: 30000 (30 seconds)
Valid Values: [0,...]
Importance: low


reconnect.backoff.max.ms
------------------------

The maximum amount of time in milliseconds to wait when reconnecting to a
broker that has repeatedly failed to connect. If provided, the backoff per host
will increase exponentially for each consecutive connection failure, up to this
maximum. After calculating the backoff increase, 20% random jitter is added to
avoid connection storms.

Type: long
Default: 1000 (1 second)
Valid Values: [0,...]
Importance: low


reconnect.backoff.ms
--------------------

The base amount of time to wait before attempting to reconnect to a given host.
This avoids repeatedly connecting to a host in a tight loop. This backoff
applies to all connection attempts by the client to a broker. This value is the
initial backoff value and will increase exponentially for each consecutive
connection failure, up to the reconnect.backoff.max.ms value.

Type: long
Default: 50
Valid Values: [0,...]
Importance: low


retries
-------

Setting a value greater than zero will cause the client to resend any request
that fails with a potentially transient error. It is recommended to set the
value to either zero or `MAX_VALUE` and use corresponding timeout parameters
to control how long a client should retry a request.

Type: int
Default: 2147483647
Valid Values: [0,...,2147483647]
Importance: low


retry.backoff.max.ms
--------------------

The maximum amount of time in milliseconds to wait when retrying a request to
the broker that has repeatedly failed. If provided, the backoff per client will
increase exponentially for each failed request, up to this maximum. To prevent
all clients from being synchronized upon retry, a randomized jitter with a
factor of 0.2 will be applied to the backoff, resulting in the backoff falling
within a range between 20% below and 20% above the computed value. If
retry.backoff.ms is set to be higher than retry.backoff.max.ms, then
retry.backoff.max.ms will be used as a constant backoff from the beginning
without any exponential increase

Type: long
Default: 1000 (1 second)
Valid Values: [0,...]
Importance: low


retry.backoff.ms
----------------

The amount of time to wait before attempting to retry a failed request to a
given topic partition. This avoids repeatedly sending requests in a tight loop
under some failure scenarios. This value is the initial backoff value and will
increase exponentially for each failed request, up to the
retry.backoff.max.ms value.

Type: long
Default: 100
Valid Values: [0,...]
Importance: low


sasl.kerberos.kinit.cmd
-----------------------

Kerberos kinit command path.

Type: string
Default: /usr/bin/kinit
Valid Values:
Importance: low


sasl.kerberos.min.time.before.relogin
-------------------------------------

Login thread sleep time between refresh attempts.

Type: long
Default: 60000
Valid Values:
Importance: low


sasl.kerberos.ticket.renew.jitter
---------------------------------

Percentage of random jitter added to the renewal time.

Type: double
Default: 0.05
Valid Values:
Importance: low


sasl.kerberos.ticket.renew.window.factor
----------------------------------------

Login thread will sleep until the specified window factor of time from last
refresh to ticket's expiry has been reached, at which time it will try to renew
the ticket.

Type: double
Default: 0.8
Valid Values:
Importance: low


sasl.login.connect.timeout.ms
-----------------------------

The (optional) value in milliseconds for the external authentication provider
connection timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low


sasl.login.read.timeout.ms
--------------------------

The (optional) value in milliseconds for the external authentication provider
read timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low


sasl.login.refresh.buffer.seconds
---------------------------------

The amount of buffer time before credential expiration to maintain when
refreshing a credential, in seconds. If a refresh would otherwise occur closer
to expiration than the number of buffer seconds then the refresh will be moved
up to maintain as much of the buffer time as possible. Legal values are between
0 and 3600 (1 hour); a default value of 300 (5 minutes) is used if no value is
specified. This value and sasl.login.refresh.min.period.seconds are both
ignored if their sum exceeds the remaining lifetime of a credential. Currently
applies only to OAUTHBEARER.

Type: short
Default: 300
Valid Values: [0,...,3600]
Importance: low


sasl.login.refresh.min.period.seconds
-------------------------------------

The desired minimum time for the login refresh thread to wait before refreshing
a credential, in seconds. Legal values are between 0 and 900 (15 minutes); a
default value of 60 (1 minute) is used if no value is specified. This value and
sasl.login.refresh.buffer.seconds are both ignored if their sum exceeds the
remaining lifetime of a credential. Currently applies only to OAUTHBEARER.

Type: short
Default: 60
Valid Values: [0,...,900]
Importance: low


sasl.login.refresh.window.factor
--------------------------------

Login refresh thread will sleep until the specified window factor relative to
the credential's lifetime has been reached, at which time it will try to
refresh the credential. Legal values are between 0.5 (50%) and 1.0 (100%)
inclusive; a default value of 0.8 (80%) is used if no value is specified.
Currently applies only to OAUTHBEARER.

Type: double
Default: 0.8
Valid Values: [0.5,...,1.0]
Importance: low


sasl.login.refresh.window.jitter
--------------------------------

The maximum amount of random jitter relative to the credential's lifetime that
is added to the login refresh thread's sleep time. Legal values are between 0
and 0.25 (25%) inclusive; a default value of 0.05 (5%) is used if no value is
specified. Currently applies only to OAUTHBEARER.

Type: double
Default: 0.05
Valid Values: [0.0,...,0.25]
Importance: low


sasl.login.retry.backoff.max.ms
-------------------------------

The (optional) value in milliseconds for the maximum wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low


sasl.login.retry.backoff.ms
---------------------------

The (optional) value in milliseconds for the initial wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 100
Valid Values:
Importance: low


sasl.oauthbearer.clock.skew.seconds
-----------------------------------

The (optional) value in seconds to allow for differences between the time of
the OAuth/OIDC identity provider and the broker.

Type: int
Default: 30
Valid Values:
Importance: low


sasl.oauthbearer.expected.audience
----------------------------------

The (optional) comma-delimited setting for the broker to use to verify that the
JWT was issued for one of the expected audiences. The JWT will be inspected for
the standard OAuth aud claim and if this value is set, the broker will
match the value from JWT's aud claim to see if there is an exact match. If
there is no match, the broker will reject the JWT and authentication will fail.

Type: list
Default: null
Valid Values:
Importance: low


sasl.oauthbearer.expected.issuer
--------------------------------

The (optional) setting for the broker to use to verify that the JWT was created
by the expected issuer. The JWT will be inspected for the standard OAuth
iss claim and if this value is set, the broker will match it exactly
against what is in the JWT's iss claim. If there is no match, the broker
will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.refresh.ms
-----------------------------------------

The (optional) value in milliseconds for the broker to wait between refreshing
its JWKS (JSON Web Key Set) cache that contains the keys to verify the
signature of the JWT.

Type: long
Default: 3600000 (1 hour)
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms
---------------------------------------------------

The (optional) value in milliseconds for the maximum wait between attempts to
retrieve the JWKS (JSON Web Key Set) from the external authentication provider.
JWKS retrieval uses an exponential backoff algorithm with an initial wait based
on the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double
in wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.retry.backoff.ms
-----------------------------------------------

The (optional) value in milliseconds for the initial wait between JWKS (JSON
Web Key Set) retrieval attempts from the external authentication provider. JWKS
retrieval uses an exponential backoff algorithm with an initial wait based on
the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double in
wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 100
Valid Values:
Importance: low


sasl.oauthbearer.scope.claim.name
---------------------------------

The OAuth claim for the scope is often named scope, but this (optional)
setting can provide a different name to use for the scope included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: scope
Valid Values:
Importance: low


sasl.oauthbearer.sub.claim.name
-------------------------------

The OAuth claim for the subject is often named sub, but this (optional)
setting can provide a different name to use for the subject included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: sub
Valid Values:
Importance: low


security.providers
------------------

A list of configurable creator classes each returning a provider implementing
security algorithms. These classes should implement the
org.apache.kafka.common.security.auth.SecurityProviderCreator interface.

Type: string
Default: null
Valid Values:
Importance: low


ssl.cipher.suites
-----------------

A list of cipher suites. This is a named combination of authentication,
encryption, MAC and key exchange algorithm used to negotiate the security
settings for a network connection using TLS or SSL network protocol. By default
all the available cipher suites are supported.

Type: list
Default: null
Valid Values:
Importance: low


ssl.endpoint.identification.algorithm
-------------------------------------

The endpoint identification algorithm to validate server hostname using server
certificate.

Type: string
Default: https
Valid Values:
Importance: low


ssl.engine.factory.class
------------------------

The class of type org.apache.kafka.common.security.auth.SslEngineFactory to
provide SSLEngine objects. Default value is
org.apache.kafka.common.security.ssl.DefaultSslEngineFactory. Alternatively,
setting this to
org.apache.kafka.common.security.ssl.CommonNameLoggingSslEngineFactory will log
the common name of expired SSL certificates used by clients to authenticate at
any of the brokers with log level INFO. Note that this will cause a tiny delay
during establishment of new connections from mTLS clients to brokers due to the
extra code for examining the certificate chain provided by the client. Note
further that the implementation uses a custom truststore based on the standard
Java truststore and thus might be considered a security risk due to not being
as mature as the standard one.

Type: class
Default: null
Valid Values:
Importance: low


ssl.keymanager.algorithm
------------------------

The algorithm used by key manager factory for SSL connections. Default value is
the key manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: SunX509
Valid Values:
Importance: low


ssl.secure.random.implementation
--------------------------------

The SecureRandom PRNG implementation to use for SSL cryptography operations.

Type: string
Default: null
Valid Values:
Importance: low


ssl.trustmanager.algorithm
--------------------------

The algorithm used by trust manager factory for SSL connections. Default value
is the trust manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: PKIX
Valid Values:
Importance: low


ssl.key.password
----------------

The password of the private key in the key store file or the PEM key specified
in 'ssl.keystore.key'.

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.certificate.chain
------------------------------

Certificate chain in the format specified by 'ssl.keystore.type'. Default SSL
engine factory supports only PEM format with a list of X.509 certificates

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.key
----------------

Private key in the format specified by 'ssl.keystore.type'. Default SSL engine
factory supports only PEM format with PKCS#8 keys. If the key is encrypted, key
password must be specified using 'ssl.key.password'

Type: password
Default: null
Valid Values:
Importance: high


ssl.keystore.location
---------------------

The location of the key store file. This is optional for client and can be used
for two-way authentication for client.

Type: string
Default: null
Valid Values:
Importance: high


ssl.keystore.password
---------------------

The store password for the key store file. This is optional for client and only
needed if 'ssl.keystore.location' is configured. Key store password is not
supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: high


ssl.truststore.certificates
---------------------------

Trusted certificates in the format specified by 'ssl.truststore.type'. Default
SSL engine factory supports only PEM format with X.509 certificates.

Type: password
Default: null
Valid Values:
Importance: high


ssl.truststore.location
-----------------------

The location of the trust store file.

Type: string
Default: null
Valid Values:
Importance: high


ssl.truststore.password
-----------------------

The password for the trust store file. If a password is not set, trust store
file configured will still be used, but integrity checking is disabled. Trust
store password is not supported for PEM format.

Type: password
Default: null
Valid Values:
Importance: high


target.cluster.alias
--------------------

Alias of target cluster. Used in metrics reporting.

Type: string
Default: target
Valid Values:
Importance: high


sasl.client.callback.handler.class
----------------------------------

The fully qualified name of a SASL client callback handler class that
implements the AuthenticateCallbackHandler interface.

Type: class
Default: null
Valid Values:
Importance: medium


sasl.jaas.config
----------------

JAAS login context parameters for SASL connections in the format used by JAAS
configuration files. JAAS configuration file format is described <a
href=https://docs.oracle.com/javase/8/docs/technotes/guides/security/jgss/tutorials/LoginConfigFile.html>here</a>.
The format for the value is: loginModuleClass controlFlag
(optionName=optionValue);. For brokers, the config must be prefixed with
listener prefix and SASL mechanism name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.jaas.config=com.example.ScramLoginModule
required;

Type: password
Default: null
Valid Values:
Importance: medium


sasl.kerberos.service.name
--------------------------

The Kerberos principal name that Kafka runs as. This can be defined either in
Kafka's JAAS config or in Kafka's config.

Type: string
Default: null
Valid Values:
Importance: medium


sasl.login.callback.handler.class
---------------------------------

The fully qualified name of a SASL login callback handler class that implements
the AuthenticateCallbackHandler interface. For brokers, login callback handler
config must be prefixed with listener prefix and SASL mechanism name in
lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.callback.handler.class=com.example.CustomScramLoginCallbackHandler

Type: class
Default: null
Valid Values:
Importance: medium


sasl.login.class
----------------

The fully qualified name of a class that implements the Login interface. For
brokers, login config must be prefixed with listener prefix and SASL mechanism
name in lower-case. For example,
listener.name.sasl_ssl.scram-sha-256.sasl.login.class=com.example.CustomScramLogin

Type: class
Default: null
Valid Values:
Importance: medium


sasl.mechanism
--------------

SASL mechanism used for client connections. This may be any mechanism for which
a security provider is available. GSSAPI is the default mechanism.

Type: string
Default: GSSAPI
Valid Values:
Importance: medium


sasl.oauthbearer.jwks.endpoint.url
----------------------------------

The OAuth/OIDC provider URL from which the provider's <a
href=https://datatracker.ietf.org/doc/html/rfc7517#section-5>JWKS (JSON Web
Key Set)</a> can be retrieved. The URL can be HTTP(S)-based or file-based. If
the URL is HTTP(S)-based, the JWKS data will be retrieved from the OAuth/OIDC
provider via the configured URL on broker startup. All then-current keys will
be cached on the broker for incoming requests. If an authentication request is
received for a JWT that includes a kid header claim value that isn't yet in
the cache, the JWKS endpoint will be queried again on demand. However, the
broker polls the URL every sasl.oauthbearer.jwks.endpoint.refresh.ms
milliseconds to refresh the cache with any forthcoming keys before any JWT
requests that include them are received. If the URL is file-based, the broker
will load the JWKS file from a configured location on startup. In the event
that the JWT includes a kid header value that isn't in the JWKS file, the
broker will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: medium


sasl.oauthbearer.token.endpoint.url
-----------------------------------

The URL for the OAuth/OIDC identity provider. If the URL is HTTP(S)-based, it
is the issuer's token endpoint URL to which requests will be made to login
based on the configuration in sasl.jaas.config. If the URL is file-based, it
specifies a file containing an access token (in JWT serialized form) issued by
the OAuth/OIDC identity provider to use for authorization.

Type: string
Default: null
Valid Values:
Importance: medium


security.protocol
-----------------

Protocol used to communicate with brokers. Valid values are: PLAINTEXT, SSL,
SASL_PLAINTEXT, SASL_SSL.

Type: string
Default: PLAINTEXT
Valid Values: (case insensitive) [SASL_SSL, PLAINTEXT, SSL, SASL_PLAINTEXT]
Importance: medium


ssl.enabled.protocols
---------------------

The list of protocols enabled for SSL connections. The default is
'TLSv1.2,TLSv1.3' when running with Java 11 or newer, 'TLSv1.2' otherwise. With
the default value for Java 11, clients and servers will prefer TLSv1.3 if both
support it and fallback to TLSv1.2 otherwise (assuming both support at least
TLSv1.2). This default should be fine for most cases. Also see the config
documentation for `ssl.protocol`.

Type: list
Default: TLSv1.2,TLSv1.3
Valid Values:
Importance: medium


ssl.keystore.type
-----------------

The file format of the key store file. This is optional for client. The values
currently supported by the default `ssl.engine.factory.class` are [JKS,
PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium


ssl.protocol
------------

The SSL protocol used to generate the SSLContext. The default is 'TLSv1.3' when
running with Java 11 or newer, 'TLSv1.2' otherwise. This value should be fine
for most use cases. Allowed values in recent JVMs are 'TLSv1.2' and 'TLSv1.3'.
    'TLS', 'TLSv1.1', 'SSL', 'SSLv2' and 'SSLv3' may be supported in older
    JVMs, but their usage is discouraged due to known security vulnerabilities.
    With the default value for this config and 'ssl.enabled.protocols', clients
    will downgrade to 'TLSv1.2' if the server does not support 'TLSv1.3'. If
    this config is set to 'TLSv1.2', clients will not use 'TLSv1.3' even if it
    is one of the values in ssl.enabled.protocols and the server only supports
    'TLSv1.3'.

Type: string
Default: TLSv1.3
Valid Values:
Importance: medium


ssl.provider
------------

The name of the security provider used for SSL connections. Default value is
the default security provider of the JVM.

Type: string
Default: null
Valid Values:
Importance: medium


ssl.truststore.type
-------------------

The file format of the trust store file. The values currently supported by the
default `ssl.engine.factory.class` are [JKS, PKCS12, PEM].

Type: string
Default: JKS
Valid Values:
Importance: medium


admin.timeout.ms
----------------

Timeout for administrative tasks, e.g. detecting new topics.

Type: long
Default: 60000 (1 minute)
Valid Values:
Importance: low


auto.include.jmx.reporter
-------------------------

Deprecated. Whether to automatically include JmxReporter even if it's not
listed in metric.reporters. This configuration will be removed in Kafka 4.0,
users should instead include org.apache.kafka.common.metrics.JmxReporter in
metric.reporters in order to enable the JmxReporter.

Type: boolean
Default: true
Valid Values:
Importance: low


enabled
-------

Whether to replicate source->target.

Type: boolean
Default: true
Valid Values:
Importance: low


forwarding.admin.class
----------------------

Class which extends ForwardingAdmin to define custom cluster resource
management (topics, configs, etc). The class must have a constructor with
signature (Map<String, Object> config) that is used to configure a
KafkaAdminClient and may also be used to configure clients for external systems
if necessary.

Type: class
Default: org.apache.kafka.clients.admin.ForwardingAdmin
Valid Values:
Importance: low


metric.reporters
----------------

A list of classes to use as metrics reporters. Implementing the
org.apache.kafka.common.metrics.MetricsReporter interface allows plugging in
classes that will be notified of new metric creation. The JmxReporter is always
included to register JMX statistics.

Type: list
Default: null
Valid Values:
Importance: low


replication.policy.class
------------------------

Class which defines the remote topic naming convention.

Type: class
Default: org.apache.kafka.connect.mirror.DefaultReplicationPolicy
Valid Values:
Importance: low


replication.policy.internal.topic.separator.enabled
---------------------------------------------------

Whether to use replication.policy.separator to control the names of topics used
for checkpoints and offset syncs. By default, custom separators are used in
    these topic names; however, if upgrading MirrorMaker 2 from older versions
    that did not allow for these topic names to be customized, it may be
    necessary to set this property to 'false' in order to continue using the
    same names for those topics.

Type: boolean
Default: true
Valid Values:
Importance: low


replication.policy.separator
----------------------------

Separator used in remote topic naming convention.

Type: string
Default: .
Valid Values:
Importance: low


sasl.kerberos.kinit.cmd
-----------------------

Kerberos kinit command path.

Type: string
Default: /usr/bin/kinit
Valid Values:
Importance: low


sasl.kerberos.min.time.before.relogin
-------------------------------------

Login thread sleep time between refresh attempts.

Type: long
Default: 60000
Valid Values:
Importance: low


sasl.kerberos.ticket.renew.jitter
---------------------------------

Percentage of random jitter added to the renewal time.

Type: double
Default: 0.05
Valid Values:
Importance: low


sasl.kerberos.ticket.renew.window.factor
----------------------------------------

Login thread will sleep until the specified window factor of time from last
refresh to ticket's expiry has been reached, at which time it will try to renew
the ticket.

Type: double
Default: 0.8
Valid Values:
Importance: low


sasl.login.connect.timeout.ms
-----------------------------

The (optional) value in milliseconds for the external authentication provider
connection timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low


sasl.login.read.timeout.ms
--------------------------

The (optional) value in milliseconds for the external authentication provider
read timeout. Currently applies only to OAUTHBEARER.

Type: int
Default: null
Valid Values:
Importance: low


sasl.login.refresh.buffer.seconds
---------------------------------

The amount of buffer time before credential expiration to maintain when
refreshing a credential, in seconds. If a refresh would otherwise occur closer
to expiration than the number of buffer seconds then the refresh will be moved
up to maintain as much of the buffer time as possible. Legal values are between
0 and 3600 (1 hour); a default value of 300 (5 minutes) is used if no value is
specified. This value and sasl.login.refresh.min.period.seconds are both
ignored if their sum exceeds the remaining lifetime of a credential. Currently
applies only to OAUTHBEARER.

Type: short
Default: 300
Valid Values: [0,...,3600]
Importance: low


sasl.login.refresh.min.period.seconds
-------------------------------------

The desired minimum time for the login refresh thread to wait before refreshing
a credential, in seconds. Legal values are between 0 and 900 (15 minutes); a
default value of 60 (1 minute) is used if no value is specified. This value and
sasl.login.refresh.buffer.seconds are both ignored if their sum exceeds the
remaining lifetime of a credential. Currently applies only to OAUTHBEARER.

Type: short
Default: 60
Valid Values: [0,...,900]
Importance: low


sasl.login.refresh.window.factor
--------------------------------

Login refresh thread will sleep until the specified window factor relative to
the credential's lifetime has been reached, at which time it will try to
refresh the credential. Legal values are between 0.5 (50%) and 1.0 (100%)
inclusive; a default value of 0.8 (80%) is used if no value is specified.
Currently applies only to OAUTHBEARER.

Type: double
Default: 0.8
Valid Values: [0.5,...,1.0]
Importance: low


sasl.login.refresh.window.jitter
--------------------------------

The maximum amount of random jitter relative to the credential's lifetime that
is added to the login refresh thread's sleep time. Legal values are between 0
and 0.25 (25%) inclusive; a default value of 0.05 (5%) is used if no value is
specified. Currently applies only to OAUTHBEARER.

Type: double
Default: 0.05
Valid Values: [0.0,...,0.25]
Importance: low


sasl.login.retry.backoff.max.ms
-------------------------------

The (optional) value in milliseconds for the maximum wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low


sasl.login.retry.backoff.ms
---------------------------

The (optional) value in milliseconds for the initial wait between login
attempts to the external authentication provider. Login uses an exponential
backoff algorithm with an initial wait based on the sasl.login.retry.backoff.ms
setting and will double in wait length between attempts up to a maximum wait
length specified by the sasl.login.retry.backoff.max.ms setting. Currently
applies only to OAUTHBEARER.

Type: long
Default: 100
Valid Values:
Importance: low


sasl.oauthbearer.clock.skew.seconds
-----------------------------------

The (optional) value in seconds to allow for differences between the time of
the OAuth/OIDC identity provider and the broker.

Type: int
Default: 30
Valid Values:
Importance: low


sasl.oauthbearer.expected.audience
----------------------------------

The (optional) comma-delimited setting for the broker to use to verify that the
JWT was issued for one of the expected audiences. The JWT will be inspected for
the standard OAuth aud claim and if this value is set, the broker will
match the value from JWT's aud claim to see if there is an exact match. If
there is no match, the broker will reject the JWT and authentication will fail.

Type: list
Default: null
Valid Values:
Importance: low


sasl.oauthbearer.expected.issuer
--------------------------------

The (optional) setting for the broker to use to verify that the JWT was created
by the expected issuer. The JWT will be inspected for the standard OAuth
iss claim and if this value is set, the broker will match it exactly
against what is in the JWT's iss claim. If there is no match, the broker
will reject the JWT and authentication will fail.

Type: string
Default: null
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.refresh.ms
-----------------------------------------

The (optional) value in milliseconds for the broker to wait between refreshing
its JWKS (JSON Web Key Set) cache that contains the keys to verify the
signature of the JWT.

Type: long
Default: 3600000 (1 hour)
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms
---------------------------------------------------

The (optional) value in milliseconds for the maximum wait between attempts to
retrieve the JWKS (JSON Web Key Set) from the external authentication provider.
JWKS retrieval uses an exponential backoff algorithm with an initial wait based
on the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double
in wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 10000 (10 seconds)
Valid Values:
Importance: low


sasl.oauthbearer.jwks.endpoint.retry.backoff.ms
-----------------------------------------------

The (optional) value in milliseconds for the initial wait between JWKS (JSON
Web Key Set) retrieval attempts from the external authentication provider. JWKS
retrieval uses an exponential backoff algorithm with an initial wait based on
the sasl.oauthbearer.jwks.endpoint.retry.backoff.ms setting and will double in
wait length between attempts up to a maximum wait length specified by the
sasl.oauthbearer.jwks.endpoint.retry.backoff.max.ms setting.

Type: long
Default: 100
Valid Values:
Importance: low


sasl.oauthbearer.scope.claim.name
---------------------------------

The OAuth claim for the scope is often named scope, but this (optional)
setting can provide a different name to use for the scope included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: scope
Valid Values:
Importance: low


sasl.oauthbearer.sub.claim.name
-------------------------------

The OAuth claim for the subject is often named sub, but this (optional)
setting can provide a different name to use for the subject included in the JWT
payload's claims if the OAuth/OIDC provider uses a different name for that
claim.

Type: string
Default: sub
Valid Values:
Importance: low


ssl.cipher.suites
-----------------

A list of cipher suites. This is a named combination of authentication,
encryption, MAC and key exchange algorithm used to negotiate the security
settings for a network connection using TLS or SSL network protocol. By default
all the available cipher suites are supported.

Type: list
Default: null
Valid Values:
Importance: low


ssl.endpoint.identification.algorithm
-------------------------------------

The endpoint identification algorithm to validate server hostname using server
certificate.

Type: string
Default: https
Valid Values:
Importance: low


ssl.engine.factory.class
------------------------

The class of type org.apache.kafka.common.security.auth.SslEngineFactory to
provide SSLEngine objects. Default value is
org.apache.kafka.common.security.ssl.DefaultSslEngineFactory. Alternatively,
setting this to
org.apache.kafka.common.security.ssl.CommonNameLoggingSslEngineFactory will log
the common name of expired SSL certificates used by clients to authenticate at
any of the brokers with log level INFO. Note that this will cause a tiny delay
during establishment of new connections from mTLS clients to brokers due to the
extra code for examining the certificate chain provided by the client. Note
further that the implementation uses a custom truststore based on the standard
Java truststore and thus might be considered a security risk due to not being
as mature as the standard one.

Type: class
Default: null
Valid Values:
Importance: low


ssl.keymanager.algorithm
------------------------

The algorithm used by key manager factory for SSL connections. Default value is
the key manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: SunX509
Valid Values:
Importance: low


ssl.secure.random.implementation
--------------------------------

The SecureRandom PRNG implementation to use for SSL cryptography operations.

Type: string
Default: null
Valid Values:
Importance: low


ssl.trustmanager.algorithm
--------------------------

The algorithm used by trust manager factory for SSL connections. Default value
is the trust manager factory algorithm configured for the Java Virtual Machine.

Type: string
Default: PKIX
Valid Values:
Importance: low


name
----

Globally unique name to use for this connector.

Type: string
Default:
Valid Values: non-empty string without ISO control characters
Importance: high


connector.class
---------------

Name or alias of the class for this connector. Must be a subclass of
org.apache.kafka.connect.connector.Connector. If the connector is
org.apache.kafka.connect.file.FileStreamSinkConnector, you can either specify
this full name, or use FileStreamSink or FileStreamSinkConnector to
make the configuration a bit shorter

Type: string
Default:
Valid Values:
Importance: high


tasks.max
---------

Maximum number of tasks to use for this connector.

Type: int
Default: 1
Valid Values: [1,...]
Importance: high


tasks.max.enforce
-----------------

(Deprecated) Whether to enforce that the tasks.max property is respected by the
connector. By default, connectors that generate too many tasks will fail, and
existing sets of tasks that exceed the tasks.max property will also be failed.
If this property is set to false, then connectors will be allowed to generate
more than the maximum number of tasks, and existing sets of tasks that exceed
the tasks.max property will be allowed to run. This property is deprecated and
will be removed in an upcoming major release.

Type: boolean
Default: true
Valid Values:
Importance: low


key.converter
-------------

Converter class used to convert between Kafka Connect format and the serialized
form that is written to Kafka. This controls the format of the keys in messages
written to or read from Kafka, and since this is independent of connectors it
allows any connector to work with any serialization format. Examples of common
formats include JSON and Avro.

Type: class
Default: null
Valid Values: A concrete subclass of org.apache.kafka.connect.storage.Converter, A class with a public, no-argument constructor
Importance: low


value.converter
---------------

Converter class used to convert between Kafka Connect format and the serialized
form that is written to Kafka. This controls the format of the values in
messages written to or read from Kafka, and since this is independent of
connectors it allows any connector to work with any serialization format.
Examples of common formats include JSON and Avro.

Type: class
Default: null
Valid Values: A concrete subclass of org.apache.kafka.connect.storage.Converter, A class with a public, no-argument constructor
Importance: low


header.converter
----------------

HeaderConverter class used to convert between Kafka Connect format and the
serialized form that is written to Kafka. This controls the format of the
header values in messages written to or read from Kafka, and since this is
independent of connectors it allows any connector to work with any
serialization format. Examples of common formats include JSON and Avro. By
default, the SimpleHeaderConverter is used to serialize header values to
strings and deserialize them by inferring the schemas.

Type: class
Default: null
Valid Values: A concrete subclass of org.apache.kafka.connect.storage.HeaderConverter, A class with a public, no-argument constructor
Importance: low


config.action.reload
--------------------

The action that Connect should take on the connector when changes in external
configuration providers result in a change in the connector's configuration
properties. A value of 'none' indicates that Connect will do nothing. A value
of 'restart' indicates that Connect should restart/reload the connector with
the updated configuration properties.The restart may actually be scheduled in
the future if the external configuration provider indicates that a
configuration value will expire in the future.

Type: string
Default: restart
Valid Values: [none, restart]
Importance: low


transforms
----------

Aliases for the transformations to be applied to records.

Type: list
Default:
Valid Values: non-null string, unique transformation aliases
Importance: low


predicates
----------

Aliases for the predicates used by transformations.

Type: list
Default:
Valid Values: non-null string, unique predicate aliases
Importance: low


errors.retry.timeout
--------------------

The maximum duration in milliseconds that a failed operation will be
reattempted. The default is 0, which means no retries will be attempted. Use -1
for infinite retries.

Type: long
Default: 0
Valid Values:
Importance: medium


errors.retry.delay.max.ms
-------------------------

The maximum duration in milliseconds between consecutive retry attempts. Jitter
will be added to the delay once this limit is reached to prevent thundering
herd issues.

Type: long
Default: 60000 (1 minute)
Valid Values:
Importance: medium


errors.tolerance
----------------

Behavior for tolerating errors during connector operation. 'none' is the
default value and signals that any error will result in an immediate connector
task failure; 'all' changes the behavior to skip over problematic records.

Type: string
Default: none
Valid Values: [none, all]
Importance: medium


errors.log.enable
-----------------

If true, write each error and the details of the failed operation and
problematic record to the Connect application log. This is 'false' by default,
so that only errors that are not tolerated are reported.

Type: boolean
Default: false
Valid Values:
Importance: medium


errors.log.include.messages
---------------------------

Whether to include in the log the Connect record that resulted in a failure.
For sink records, the topic, partition, offset, and timestamp will be logged.
For source records, the key and value (and their schemas), all headers, and the
timestamp, Kafka topic, Kafka partition, source partition, and source offset
will be logged. This is 'false' by default, which will prevent record keys,
values, and headers from being written to log files.

Type: boolean
Default: false
Valid Values:
Importance: medium


config.properties.exclude
-------------------------

Topic config properties that should not be replicated. Supports comma-separated
property names and regexes.

Type: list
Default: follower.replication.throttled.replicas,leader.replication.throttled.replicas,message.timestamp.difference.max.ms,message.timestamp.type,unclean.leader.election.enable,min.insync.replicas
Valid Values:
Importance: high


topics
------

Topics to replicate. Supports comma-separated topic names and regexes.

Type: list
Default: .
Valid Values:
Importance: high


topics.blacklist
----------------

Deprecated. Use topics.exclude instead.

Type: list
Default: null
Valid Values:
Importance: high


topics.exclude
--------------

Excluded topics. Supports comma-separated topic names and regexes. Excludes
take precedence over includes.

Type: list
Default: .[-.]internal,..replica,__.
Valid Values:
Importance: high


add.source.alias.to.metrics
---------------------------

Deprecated. Whether to tag metrics with the source cluster alias. Metrics have
the target, topic and partition tags. When this setting is enabled, it adds the
source tag. This configuration will be removed in Kafka 4.0 and the default
behavior will be to always have the source tag.

Type: boolean
Default: false
Valid Values:
Importance: low


config.property.filter.class
----------------------------

ConfigPropertyFilter to use. Selects topic config properties to replicate.

Type: class
Default: org.apache.kafka.connect.mirror.DefaultConfigPropertyFilter
Valid Values:
Importance: low


consumer.poll.timeout.ms
------------------------

Timeout when polling source cluster.

Type: long
Default: 1000 (1 second)
Valid Values:
Importance: low


offset-syncs.topic.location
---------------------------

The location (source/target) of the offset-syncs topic.

Type: string
Default: source
Valid Values: [source, target]
Importance: low


offset-syncs.topic.replication.factor
-------------------------------------

Replication factor for offset-syncs topic.

Type: short
Default: 3
Valid Values:
Importance: low


offset.lag.max
--------------

How out-of-sync a remote partition can be before it is resynced.

Type: long
Default: 100
Valid Values:
Importance: low


refresh.topics.enabled
----------------------

Whether to periodically check for new topics and partitions.

Type: boolean
Default: true
Valid Values:
Importance: low


refresh.topics.interval.seconds
-------------------------------

Frequency of topic refresh.

Type: long
Default: 600
Valid Values:
Importance: low


replication.factor
------------------

Replication factor for newly created remote topics.

Type: int
Default: 2
Valid Values:
Importance: low


sync.topic.acls.enabled
-----------------------

Whether to periodically configure remote topic ACLs to match their
corresponding upstream topics.

Type: boolean
Default: true
Valid Values:
Importance: low


sync.topic.acls.interval.seconds
--------------------------------

Frequency of topic ACL sync.

Type: long
Default: 600
Valid Values:
Importance: low


sync.topic.configs.enabled
--------------------------

Whether to periodically configure remote topics to match their corresponding
upstream topics.

Type: boolean
Default: true
Valid Values:
Importance: low


sync.topic.configs.interval.seconds
-----------------------------------

Frequency of topic config sync.

Type: long
Default: 600
Valid Values:
Importance: low


topic.filter.class
------------------

TopicFilter to use. Selects topics to replicate.

Type: class
Default: org.apache.kafka.connect.mirror.DefaultTopicFilter
Valid Values:
Importance: low


use.incremental.alter.configs
-----------------------------

Deprecated. Which API to use for syncing topic configs. The valid values are
'requested', 'required' and 'never'. By default, set to 'requested', which
means the IncrementalAlterConfigs API is being used for syncing topic
configurations and if any request receives an error from an incompatible
broker, it will fallback to using the deprecated AlterConfigs API. If
explicitly set to 'required', the IncrementalAlterConfigs API is used without
the fallback logic and +if it receives an error from an incompatible broker,
the connector will fail.If explicitly set to 'never', the AlterConfig is always
used.This setting will be removed and the behaviour of 'required' will be used
in Kafka 4.0, therefore users should ensure that target broker is at least
2.3.0

Type: string
Default: requested
Valid Values: [requested, required, never]
Importance: low


groups.blacklist
----------------

Deprecated. Use groups.exclude instead.

Type: list
Default: null
Valid Values:
Importance: high


groups.exclude
--------------

Exclude groups. Supports comma-separated group IDs and regexes. Excludes take
precedence over includes.

Type: list
Default: console-consumer-.,connect-.,__.
Valid Values:
Importance: high


checkpoints.topic.replication.factor
------------------------------------

Replication factor for checkpoints topic.

Type: short
Default: 3
Valid Values:
Importance: low


consumer.poll.timeout.ms
------------------------

Timeout when polling source cluster.

Type: long
Default: 1000 (1 second)
Valid Values:
Importance: low


emit.checkpoints.enabled
------------------------

Whether to replicate consumer offsets to target cluster.

Type: boolean
Default: true
Valid Values:
Importance: low


emit.checkpoints.interval.seconds
---------------------------------

Frequency of checkpoints.

Type: long
Default: 60
Valid Values:
Importance: low


group.filter.class
------------------

GroupFilter to use. Selects consumer groups to replicate.

Type: class
Default: org.apache.kafka.connect.mirror.DefaultGroupFilter
Valid Values:
Importance: low


offset-syncs.topic.location
---------------------------

The location (source/target) of the offset-syncs topic.

Type: string
Default: source
Valid Values: [source, target]
Importance: low


refresh.groups.enabled
----------------------

Whether to periodically check for new consumer groups.

Type: boolean
Default: true
Valid Values:
Importance: low


refresh.groups.interval.seconds
-------------------------------

Frequency of group refresh.

Type: long
Default: 600
Valid Values:
Importance: low


sync.group.offsets.enabled
--------------------------

Whether to periodically write the translated offsets to `__consumer_offsets`
topic in target cluster, as long as no active consumers in that group are
connected to the target cluster

Type: boolean
Default: false
Valid Values:
Importance: low


sync.group.offsets.interval.seconds
-----------------------------------

Frequency of consumer group offset sync.

Type: long
Default: 60
Valid Values:
Importance: low


topic.filter.class
------------------

TopicFilter to use. Selects topics to replicate.

Type: class
Default: org.apache.kafka.connect.mirror.DefaultTopicFilter
Valid Values:
Importance: low


emit.heartbeats.interval.seconds
--------------------------------

Frequency of heartbeats.

Type: long
Default: 1
Valid Values:
Importance: low


heartbeats.topic.replication.factor
-----------------------------------

Replication factor for heartbeats topic.

Type: short
Default: 3
Valid Values:
Importance: low


log.local.retention.ms
----------------------

The number of milliseconds to keep the local log segments before it gets
eligible for deletion. Default value is -2, it represents `log.retention.ms`
value is to be used. The effective value should always be less than or equal to
`log.retention.ms` value.

Type: long
Default: -2
Valid Values: [-2,...]
Importance: medium


remote.fetch.max.wait.ms
------------------------

The maximum amount of time the server will wait before answering the remote
fetch request

Type: int
Default: 500
Valid Values: [1,...]
Importance: medium


remote.log.manager.copy.max.bytes.per.second
--------------------------------------------

The maximum number of bytes that can be copied from local storage to remote
storage per second. This is a global limit for all the partitions that are
being copied from local storage to remote storage. The default value is
Long.MAX_VALUE, which means there is no limit on the number of bytes that can
be copied per second.

Type: long
Default: 9223372036854775807
Valid Values: [1,...]
Importance: medium


remote.log.manager.copy.quota.window.num
----------------------------------------

The number of samples to retain in memory for remote copy quota management. The
default value is 11, which means there are 10 whole windows + 1 current window.

Type: int
Default: 11
Valid Values: [1,...]
Importance: medium


remote.log.manager.copy.quota.window.size.seconds
-------------------------------------------------

The time span of each sample for remote copy quota management. The default
value is 1 second.

Type: int
Default: 1
Valid Values: [1,...]
Importance: medium


remote.log.manager.fetch.max.bytes.per.second
---------------------------------------------

The maximum number of bytes that can be fetched from remote storage to local
storage per second. This is a global limit for all the partitions that are
being fetched from remote storage to local storage. The default value is
Long.MAX_VALUE, which means there is no limit on the number of bytes that can
be fetched per second.

Type: long
Default: 9223372036854775807
Valid Values: [1,...]
Importance: medium


remote.log.manager.fetch.quota.window.num
-----------------------------------------

The number of samples to retain in memory for remote fetch quota management.
The default value is 11, which means there are 10 whole windows + 1 current
window.

Type: int
Default: 11
Valid Values: [1,...]
Importance: medium


remote.log.manager.fetch.quota.window.size.seconds
--------------------------------------------------

The time span of each sample for remote fetch quota management. The default
value is 1 second.

Type: int
Default: 1
Valid Values: [1,...]
Importance: medium


remote.log.manager.thread.pool.size
-----------------------------------

Size of the thread pool used in scheduling tasks to copy segments, fetch remote
log indexes and clean up remote log segments.

Type: int
Default: 10
Valid Values: [1,...]
Importance: medium


remote.log.metadata.manager.class.name
--------------------------------------

Fully qualified class name of `RemoteLogMetadataManager` implementation.

Type: string
Default: org.apache.kafka.server.log.remote.metadata.storage.TopicBasedRemoteLogMetadataManager
Valid Values: non-empty string
Importance: medium


remote.log.metadata.manager.class.path
--------------------------------------

Class path of the `RemoteLogMetadataManager` implementation. If specified,
the RemoteLogMetadataManager implementation and its dependent libraries will be
loaded by a dedicated classloader which searches this class path before the
Kafka broker class path. The syntax of this parameter is same as the standard
Java class path string.

Type: string
Default: null
Valid Values:
Importance: medium


remote.log.metadata.manager.impl.prefix
---------------------------------------

Prefix used for properties to be passed to RemoteLogMetadataManager
implementation. For example this value can be `rlmm.config.`.

Type: string
Default: rlmm.config.
Valid Values: non-empty string
Importance: medium


remote.log.metadata.manager.listener.name
-----------------------------------------

Listener name of the local broker to which it should get connected if needed by
RemoteLogMetadataManager implementation.

Type: string
Default: null
Valid Values: non-empty string
Importance: medium


remote.log.reader.max.pending.tasks
-----------------------------------

Maximum remote log reader thread pool task queue size. If the task queue is
full, fetch requests are served with an error.

Type: int
Default: 100
Valid Values: [1,...]
Importance: medium


remote.log.reader.threads
-------------------------

Size of the thread pool that is allocated for handling remote log reads.

Type: int
Default: 10
Valid Values: [1,...]
Importance: medium


remote.log.storage.manager.class.name
-------------------------------------

Fully qualified class name of `RemoteStorageManager` implementation.

Type: string
Default: null
Valid Values: non-empty string
Importance: medium


remote.log.storage.manager.class.path
-------------------------------------

Class path of the `RemoteStorageManager` implementation. If specified, the
RemoteStorageManager implementation and its dependent libraries will be loaded
by a dedicated classloader which searches this class path before the Kafka
broker class path. The syntax of this parameter is same as the standard Java
class path string.

Type: string
Default: null
Valid Values:
Importance: medium


remote.log.storage.manager.impl.prefix
--------------------------------------

Prefix used for properties to be passed to RemoteStorageManager implementation.
For example this value can be `rsm.config.`.

Type: string
Default: rsm.config.
Valid Values: non-empty string
Importance: medium


remote.log.storage.system.enable
--------------------------------

Whether to enable tiered storage functionality in a broker or not. Valid values
are `true` or `false` and the default value is false. When it is true
broker starts all the services required for the tiered storage functionality.

Type: boolean
Default: false
Valid Values:
Importance: medium


remote.log.index.file.cache.total.size.bytes
--------------------------------------------

The total size of the space allocated to store index files fetched from remote
storage in the local storage.

Type: long
Default: 1073741824 (1 gibibyte)
Valid Values: [1,...]
Importance: low


remote.log.manager.task.interval.ms
-----------------------------------

Interval at which remote log manager runs the scheduled tasks like copy
segments, and clean up remote log segments.

Type: long
Default: 30000 (30 seconds)
Valid Values: [1,...]
Importance: low


remote.log.metadata.custom.metadata.max.bytes
---------------------------------------------

The maximum size of custom metadata in bytes that the broker should accept from
a remote storage plugin. If custom metadata exceeds this limit, the updated
segment metadata will not be stored, the copied data will be attempted to
delete, and the remote copying task for this topic-partition will stop with an
error.

Type: int
Default: 128
Valid Values: [0,...]
Importance: low


remote.log.metadata.initialization.retry.interval.ms
----------------------------------------------------

The retry interval in milliseconds for retrying RemoteLogMetadataManager
resources initialization again.

Type: long
Default: 100
Valid Values: [0,...]
Importance: low


remote.log.metadata.initialization.retry.max.timeout.ms
-------------------------------------------------------

The maximum amount of time in milliseconds for retrying
RemoteLogMetadataManager resources initialization. When total retry intervals
reach this timeout, initialization is considered as failed and broker starts
shutting down.

Type: long
Default: 120000 (2 minutes)
Valid Values: [0,...]
Importance: low


remote.log.metadata.topic.num.partitions
----------------------------------------

The number of partitions for remote log metadata topic.

Type: int
Default: 50
Valid Values: [1,...]
Importance: low


remote.log.metadata.topic.replication.factor
--------------------------------------------

Replication factor of remote log metadata topic.

Type: short
Default: 3
Valid Values: [1,...]
Importance: low


remote.log.metadata.topic.retention.ms
--------------------------------------

Retention of remote log metadata topic in milliseconds. Default: -1, that means
unlimited. Users can configure this value based on their use cases. To avoid
any data loss, this value should be more than the maximum retention period of
any topic enabled with tiered storage in the cluster.

Type: long
Default: -1
Valid Values:
Importance: low
