package com.bcp.codapp.kafka.connect.smt.model.squema;

import com.bcp.codapp.kafka.connect.smt.util.AvroObject;
import org.apache.kafka.connect.data.Schema;
import org.apache.kafka.connect.data.SchemaBuilder;

public class CardOnlineSchema {

  public static Schema CARD_SCHEMA = SchemaBuilder.struct().name(AvroObject.TAG_CARD.getText())
      .version(1)
      .field("cardId", Schema.STRING_SCHEMA)
      .field("expirationDate", Schema.STRING_SCHEMA)
      .build();
  public static  Schema REPOSITION_CARD_SCHEMA = SchemaBuilder.struct().name(AvroObject.TAG_REPOSITION_CARD.getText())
      .version(1)
      .field("repositionCardId", Schema.STRING_SCHEMA)
      .field("expirationDate", Schema.STRING_SCHEMA)
      .build();
  public static  Schema OPERATION_SCHEMA = SchemaBuilder.struct().name(AvroObject.TAG_OPERATION.getText())
      .version(1)
      .field("operationType", Schema.STRING_SCHEMA)
      .field("operationDate", Schema.STRING_SCHEMA)
      .field("lockingCode", Schema.STRING_SCHEMA)
      .build();
  public static  Schema CARD_OPERATION_SCHEMA = SchemaBuilder.struct().name(AvroObject.TAG_OPERATION.getText())
      .version(1)
      .field("repositionCard", REPOSITION_CARD_SCHEMA)
      .field("card", CARD_SCHEMA)
      .field("operation", OPERATION_SCHEMA)
      .build();
  public static  Schema ARRAY_CARD_SCHEMA = SchemaBuilder.array(CARD_OPERATION_SCHEMA).optional().build();

  public static   Schema MESSAGE_SCHEMA = SchemaBuilder.struct()
      .field(AvroObject.MESSAGE_KEY.getText(), ARRAY_CARD_SCHEMA)
      .build();



}

