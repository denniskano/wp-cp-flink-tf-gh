package com.bcp.codapp.kafka.connect.smt.builder.online;

import com.bcp.codapp.kafka.connect.smt.model.online.CardItemNS67;
import com.bcp.codapp.kafka.connect.smt.model.squema.CardOnlineSchema;
import java.util.Arrays;
import com.bcp.codapp.kafka.connect.smt.util.AvroObject;
import com.bcp.codapp.kafka.connect.smt.util.Constants;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.connect.data.SchemaAndValue;
import java.util.List;
import org.apache.kafka.connect.data.Struct;

@Slf4j
public class MessageBodyBuilder {


    public SchemaAndValue buildMessage( CardItemNS67 cardItemNS67){
        log.info(" MessageBodyBuilder -> buildMessage ");

        Struct cardOperationStruct = new Struct(CardOnlineSchema.CARD_OPERATION_SCHEMA);
        setRepositionCard(cardOperationStruct,cardItemNS67);
        setCard(cardOperationStruct,cardItemNS67);
        setOperation(cardOperationStruct,cardItemNS67);
        List<Struct> cardOperationStructList = Arrays.asList(cardOperationStruct);
        Struct message = new Struct(CardOnlineSchema.MESSAGE_SCHEMA);
        message.put(AvroObject.MESSAGE_KEY.getText(),cardOperationStructList);
        log.info(" MessageBodyBuilder ->  buildMessage tranformer apply ");
        return new SchemaAndValue(CardOnlineSchema.MESSAGE_SCHEMA,message);

    }

    private void setRepositionCard(Struct cardOperationStruct, CardItemNS67 cardItemNS67) {
        Struct repositionCardRecord = new Struct(CardOnlineSchema.REPOSITION_CARD_SCHEMA);
        if (cardItemNS67.getOperationCard().equalsIgnoreCase(Constants.ESTADO)) {
            repositionCardRecord.put("repositionCardId", Constants.EMPTY);
            repositionCardRecord.put("expirationDate", Constants.EMPTY);
        } else if (cardItemNS67.getOperationCard().equalsIgnoreCase(Constants.TARJETA)) {
            repositionCardRecord.put("repositionCardId",cardItemNS67.getRepositionCardId());
            repositionCardRecord.put("expirationDate",cardItemNS67.getExpirationDate());
        }
        cardOperationStruct.put("repositionCard", repositionCardRecord);
    }
    private void setCard(Struct cardOperationStruct, CardItemNS67 cardItemNS67) {
        Struct cardStruct = new Struct(CardOnlineSchema.CARD_SCHEMA);
        cardStruct.put("cardId",cardItemNS67.getCardId());
        cardStruct.put("expirationDate",cardItemNS67.getExpirationDateCurrentCard());
        cardOperationStruct.put("card", cardStruct);
    }
    private void setOperation(Struct cardOperationStruct, CardItemNS67 cardItemNS67) {
        Struct operationStruct = new Struct(CardOnlineSchema.OPERATION_SCHEMA);
        if (cardItemNS67.getOperationCard().equalsIgnoreCase(Constants.ESTADO)) {
            operationStruct.put("operationType",Constants.ESTADO);
        }else if (cardItemNS67.getOperationCard().equalsIgnoreCase(Constants.TARJETA)) {
            operationStruct.put("operationType",Constants.TARJETA);
        }
        operationStruct.put("operationDate", cardItemNS67.getOperationDate());
        operationStruct.put("lockingCode", cardItemNS67.getLockingCode());
        cardOperationStruct.put("operation",operationStruct);
    }


}

