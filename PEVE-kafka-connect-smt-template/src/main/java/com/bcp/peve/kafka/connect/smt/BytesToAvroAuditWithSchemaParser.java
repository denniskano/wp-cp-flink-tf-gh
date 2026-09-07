package com.bcp.peve.kafka.connect.smt;

import com.bcp.atlas.core.starter.audit.model.avro.AvroAudit;
import com.bcp.peve.kafka.connect.smt.transformation.SMTRecord;
import lombok.extern.slf4j.Slf4j;
import org.apache.avro.io.DatumReader;
import org.apache.avro.io.Decoder;
import org.apache.avro.io.DecoderFactory;
import org.apache.avro.specific.SpecificDatumReader;
import org.apache.kafka.connect.connector.ConnectRecord;
import org.apache.kafka.connect.data.*;

import java.io.IOException;
import java.util.*;

@Slf4j
public abstract class BytesToAvroAuditWithSchemaParser<R extends ConnectRecord<R>> extends SMTRecord<R> {


    protected BytesToAvroAuditWithSchemaParser(boolean isKey) {
        super(isKey);
    }

    public static class Key<R extends ConnectRecord<R>> extends BytesToAvroAuditWithSchemaParser<R> {
        public Key() {
            super(true);
        }
    }

    public static class Value<R extends ConnectRecord<R>> extends BytesToAvroAuditWithSchemaParser<R> {
        public Value() {
            super(false);
        }
    }

    @Override
    protected SchemaAndValue processKeyAndValue(R record) {
        log.info("{BytesToAvroAuditWithSchemaParser -> processKeyAndValue}");
        SchemaAndValue schemaAndValue = applyWithSchema(record);
        if( schemaAndValue == null) {
            return new SchemaAndValue(record.keySchema(),record.value());
        }
        return schemaAndValue;

    }


    public static AvroAudit deSerialize(byte[] data) {
        DatumReader<AvroAudit> reader
                = new SpecificDatumReader<>(AvroAudit.class);
        try {
            Decoder decoder = DecoderFactory.get().binaryDecoder(data, null);
            return reader.read(null, decoder);
        } catch (IOException e) {
            log.error("Deserialization error:" + e.getMessage());
        }
        return null;
    }

    private SchemaAndValue applyWithSchema(R record) {
        AvroAudit avroAudit = deSerialize((byte[]) record.value());
        if(isDebug) {
            log.info("AvroAudit from bytes = " + avroAudit);
        }
        if(avroAudit != null) {
            final Schema SCOPES_SCHEMA = SchemaBuilder.array(
                    Schema.STRING_SCHEMA
            ).optional().build();
            final Schema DATA_SCHEMA = SchemaBuilder.map(
                    Schema.STRING_SCHEMA,
                    Schema.OPTIONAL_STRING_SCHEMA
            ).build();
            final Schema EXTERNAL_DATA_SCHEMA = SchemaBuilder.map(
                    Schema.STRING_SCHEMA,
                    Schema.STRING_SCHEMA
            ).optional().build();
            final SchemaBuilder schemaBuilder = new SchemaBuilder(Schema.Type.STRUCT);
            schemaBuilder.field("eventId", Schema.STRING_SCHEMA);
            schemaBuilder.field("requestId", Schema.STRING_SCHEMA);
            schemaBuilder.field("requestDate", Schema.OPTIONAL_STRING_SCHEMA);
            schemaBuilder.field("channel", Schema.STRING_SCHEMA);
            schemaBuilder.field("eventType", Schema.STRING_SCHEMA);
            schemaBuilder.field("entityType", Schema.STRING_SCHEMA);
            schemaBuilder.field("entityId", Schema.OPTIONAL_STRING_SCHEMA);
            schemaBuilder.field("applicationGroup", Schema.STRING_SCHEMA);
            schemaBuilder.field("scopes", SCOPES_SCHEMA);
            schemaBuilder.field("result", Schema.STRING_SCHEMA);
            schemaBuilder.field("errorReason", Schema.OPTIONAL_STRING_SCHEMA);
            schemaBuilder.field("data", DATA_SCHEMA);
            schemaBuilder.field("externalData", EXTERNAL_DATA_SCHEMA);
            schemaBuilder.name("AvroAudit");
            Schema schema = schemaBuilder.build();

            Struct struct = new Struct(schema);

            for (final Field field : schema.fields()) {
                String fieldName = field.name();
                Object fieldValue = avroAudit.get(fieldName);
                if (fieldValue != null) {
                    if (fieldValue instanceof List) {
                        ListIterator iterator = ((List) fieldValue).listIterator();
                        while (iterator.hasNext()){
                            Object s = iterator.next();
                            iterator.set(s!=null? s.toString():null);
                        }
                        struct.put(field, fieldValue);
                    } else if (fieldValue instanceof Map) {
                        Map<Object, Object> newMap = new HashMap<>();
                        Iterator<Map.Entry<Object, Object>> iterator = ((Map) fieldValue).entrySet().iterator();
                        while (iterator.hasNext()) {
                            Map.Entry<Object, Object> entry = iterator.next();
                            iterator.remove();
                            newMap.put(entry.getKey() != null ?entry.getKey().toString(): null,
                                    entry.getValue() != null ? entry.getValue().toString() : null);
                        }
                        struct.put(field, newMap);
                    } else {
                        struct.put(field, fieldValue.toString());
                    }
                }else{
                    struct.put(field, null);
                    if(isDebug) {
                        log.info("No se encontro valores para el atributo = " + fieldName);
                    }
                }
            }
            if(isDebug) {
                log.info(" Creando el evento con struct = " + struct);
            }
            SchemaAndValue schemaAndValue = new SchemaAndValue(schema,struct);

            return schemaAndValue;
        }
        return null;
    }
}
