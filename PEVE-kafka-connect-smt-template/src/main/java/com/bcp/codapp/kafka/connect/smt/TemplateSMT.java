package com.bcp.codapp.kafka.connect.smt;

import com.bcp.peve.kafka.connect.smt.transformation.SMTRecord;
import org.apache.kafka.connect.connector.ConnectRecord;
import org.apache.kafka.connect.data.SchemaAndValue;

// Reemplazar TemplateSMT por el nombre definido para tu transformer
public abstract class TemplateSMT<R extends ConnectRecord<R>> extends SMTRecord<R> {

    protected TemplateSMT(boolean isKey) {
        super(isKey);
    }

    // Reemplazar TemplateSMT por el nombre definido para tu transformer
    public static class Key<R extends ConnectRecord<R>> extends TemplateSMT<R> {
        public Key() {
            super(true);
        }
    }

    // Reemplazar TemplateSMT por el nombre definido para tu transformer
    public static class Value<R extends ConnectRecord<R>> extends TemplateSMT<R> {
        public Value() {
            super(false);
        }
    }

    @Override
    protected SchemaAndValue processKeyAndValue(R record){
        // Implementar logica de tu transformer aqui
        return null;
    }
}

