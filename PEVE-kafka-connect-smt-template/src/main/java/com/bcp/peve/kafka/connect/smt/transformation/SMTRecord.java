package com.bcp.peve.kafka.connect.smt.transformation;

import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.connect.connector.ConnectRecord;
import org.apache.kafka.connect.data.SchemaAndValue;
import org.apache.kafka.connect.transforms.Transformation;
import org.apache.kafka.connect.transforms.util.SimpleConfig;

import java.util.Map;

@Slf4j
public abstract class SMTRecord<R extends ConnectRecord<R>> implements Transformation<R> {

    public static final ConfigDef CONFIG_DEF = new ConfigDef()
            .define("debug", ConfigDef.Type.STRING, "false", ConfigDef.Importance.LOW,
                    "Debug mode for SMTRecord implementation");
    protected final boolean isKey;

    protected boolean isDebug = false;


    protected SMTRecord(boolean isKey) {
        this.isKey = isKey;
    }

    @Override
    public void configure(Map<String, ?> props) {
        log.info("{SMTRecord -> configure}");
        log.info("{SMTRecord -> props -> " + props + " }");
        final SimpleConfig config = new SimpleConfig(CONFIG_DEF, props);
        String isDebugStr = config.getString("debug");
        if(isDebugStr != null) {
            isDebug = Boolean.parseBoolean(isDebugStr);
        }
        log.info("{configure isDebug -> }" + isDebug);
    }


    @Override
    public ConfigDef config() {
        return CONFIG_DEF;
    }

    @Override
    public R apply(R record) {
        log.info("{SMTRecord -> apply}");
        if(isDebug) {
            log.info("{Data -> }" + record.value());
            log.info("{Schema -> }" + record.keySchema());
        }
        SchemaAndValue transformedRecord = processKeyAndValue(record);

        return record.newRecord(record.topic(), record.kafkaPartition(),
                                record.keySchema(), record.key(),
                                transformedRecord.schema(), transformedRecord.value(),
                                record.timestamp());
    }


    @Override
    public void close() {
        // TODO Auto-generated method stub
    }

    protected abstract SchemaAndValue processKeyAndValue(R record);

}

