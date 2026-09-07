package com.bcp.codapp.kafka.connect.smt;


import com.bcp.codapp.kafka.connect.smt.builder.online.MessageBodyBuilder;
import com.bcp.codapp.kafka.connect.smt.model.online.CardItemNS67;
import com.bcp.peve.kafka.connect.smt.transformation.SMTRecord;
import com.bcp.codapp.kafka.connect.smt.util.online.ParserPositional;
import java.security.SecureRandom;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.connect.connector.ConnectRecord;
import org.apache.kafka.connect.data.SchemaAndValue;

@Slf4j
public class CardPositionalToJsonParser<R extends ConnectRecord<R>> extends SMTRecord<R> {


    private MessageBodyBuilder messageBodyBuilder = new MessageBodyBuilder();
    private static final SecureRandom secureRandom = new SecureRandom();


    public CardPositionalToJsonParser(boolean isKey, MessageBodyBuilder messageBodyBuilder ) {
        super(isKey);
        this.messageBodyBuilder = messageBodyBuilder;
    }


    protected CardPositionalToJsonParser(boolean isKey) {
        super(isKey);
    }

    public static class Key<R extends ConnectRecord<R>> extends CardPositionalToJsonParser<R> {
        public Key() {
            super(true);
        }
    }

    public static class Value<R extends ConnectRecord<R>> extends CardPositionalToJsonParser<R> {
        public Value() {
            super(false);
        }
    }

    @Override
    protected SchemaAndValue processKeyAndValue(R record) {
        log.info("{CardPositionalToJsonParser -> processKeyAndValue}");
        CardItemNS67 cardItemNS67 = ParserPositional.parseBodyPositional(record.value());
        return messageBodyBuilder.buildMessage(cardItemNS67);

    }



}

