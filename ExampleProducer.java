public static void main(String[] args) throws ExecutionException, InterruptedException {

    Properties props = new Properties();
    props.put(ProducerConfig.BOOTSTRAP_SERVER_CONFIG, "localhost1:9092,localhost2:9093,localhost:9094");
    props.put(ProducerConfig.KEY_SERIALIZER_CONFIG, StringSerializer.class.getName());
    props.put(ProducerConfig.VALUE_SERIALIZER_CONFIG, StringSerializer.class.getName());

    KafkaProducer<String, String> producer = new KafkaProducer<>(props);

    String key = "nigdy_tak_nie_rob";
    String value = "{ 'message': 1 }";

    ProducerRecord<String, String> record = new ProducerRecord<>("topic1", key, value);

    producer.send(record);

    producer.flush();
}
