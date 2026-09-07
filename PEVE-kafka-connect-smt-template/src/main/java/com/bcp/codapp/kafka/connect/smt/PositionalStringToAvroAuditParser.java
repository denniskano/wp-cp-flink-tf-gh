
package com.bcp.codapp.kafka.connect.smt;

import com.bcp.atlas.core.starter.audit.model.avro.AvroAudit;
import com.bcp.codapp.kafka.connect.smt.builder.NotificationBuilder;
import com.bcp.peve.kafka.connect.smt.transformation.SMTRecord;
import lombok.extern.slf4j.Slf4j;
import org.apache.avro.io.BinaryEncoder;
import org.apache.avro.io.DatumWriter;
import org.apache.avro.io.EncoderFactory;
import org.apache.avro.specific.SpecificDatumWriter;
import org.apache.kafka.connect.connector.ConnectRecord;
import org.apache.kafka.connect.data.Schema;
import org.apache.kafka.connect.data.SchemaAndValue;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.security.SecureRandom;

@Slf4j
public abstract class PositionalStringToAvroAuditParser<R extends ConnectRecord<R>> extends SMTRecord<R> {

    private static final SecureRandom secureRandom = new SecureRandom();

    protected PositionalStringToAvroAuditParser(boolean isKey) {
        super(isKey);
    }

    public static class Key<R extends ConnectRecord<R>> extends PositionalStringToAvroAuditParser<R> {
        public Key() {
            super(true);
        }
    }

    public static class Value<R extends ConnectRecord<R>> extends PositionalStringToAvroAuditParser<R> {
        public Value() {
            super(false);
        }
    }

    @Override
    protected SchemaAndValue processKeyAndValue(R record){
        log.info("{PositionalStringToAvroAuditParser -> processKeyAndValue}");
        final AvroAudit transformed = NotificationBuilder.buildMessage(record.value().toString());
        final byte[] avroAuditBytes = serialize(transformed);
        if(avroAuditBytes == null ) {
            return new SchemaAndValue(record.keySchema(), record.value());
        }
        SchemaAndValue schemaAndValue = new SchemaAndValue(Schema.BYTES_SCHEMA, serialize(transformed));
        return schemaAndValue;
    }

    public byte[] serialize(AvroAudit element)  {

        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {

            DatumWriter<AvroAudit> writer = new SpecificDatumWriter<>(element.getSchema());

            BinaryEncoder encoder = EncoderFactory.get().binaryEncoder(out, null);

            writer.write(element, encoder);

            encoder.flush();

            return out.toByteArray();

        } catch (IOException e) {

            log.error("Error validating & serializing with avro schema.", e);

            //throw e;

        }
        return null;

    }
}


