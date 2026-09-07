package com.bcp.codapp.kafka.connect.smt.model.online;

import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;
import org.beanio.annotation.Field;
import org.beanio.annotation.Record;

import java.io.Serializable;

@Getter
@Setter
@Record
@ToString
@EqualsAndHashCode
public class CardItemNS67 implements Serializable {

    @Field(at = 0, length = 16)
    private String cardId;
    @Field(at = 16, length = 16)
    private String repositionCardId;
    @Field(at = 32, length = 32)
    private String referenceId;
    @Field(at = 64, length = 4)
    private String expirationDate;
    @Field(at = 68, length = 2)
    private String lockingCode;
    @Field(at = 70, length = 10, trim = true)
    private String operationCard;
    @Field(at = 80, length = 8)
    private String operationDate;
    @Field(at = 88, length = 2)
    private String chanelCode;
    @Field(at = 90, length = 20)
    private String chanelDescription;
    @Field(at = 110, length = 4)
    private String expirationDateCurrentCard;
    @Field(at = 114, length = 10)
    private String freeField;


}

