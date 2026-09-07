package com.bcp.codapp.kafka.connect.smt.model.online;


import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;
import org.beanio.annotation.Field;
import org.beanio.annotation.Record;
import org.beanio.annotation.Segment;

import java.io.Serializable;
import java.util.List;

/**
 * Clase que representa un modelo de presentacion de datos
 * que ser? expuesta por la api<br/>
 * <b>Class</b>: Foo<br/>
 * <b>Copyright</b>: &copy; 2021 Banco de Cr&eacute;dito del Per&uacute;.<br/>
 * <b>Company</b>: Banco de Cr&eacute;dito del Per&uacute;.<br/>
 *
 * @author Banco de Cr&eacute;dito del Per&uacute; (BCP) <br/>
 * <u>Service Provider</u>: TCS <br/>
 * <u>Developed by</u>: <br/>
 * <ul>
 * <li>Jonathan Rojas</li>
 * </ul>
 * <u>Changes</u>:<br/>
 * <ul>
 * <li>Jan 18, 2021 Creaci&oacute;n de Clase.</li>
 * </ul>
 * @version 1.0
 */
@Getter
@Setter
@ToString
@EqualsAndHashCode
@Record
public class CardOperationOnline implements Serializable {
    @Field(at = 0, length = 2)
    private String appCode;
    @Field(at = 2, length = 1)
    private String institutionCode;
    @Field(at = 3, length = 12)
    private String serviceCode;
    @Field(at = 15, length = 4)
    private String interfaz;
    @Field(at = 19, length = 6)
    private String actionType;
    @Field(at = 25, length = 2)
    private String returnCode;
    @Field(at = 27, length = 4)
    private String detailCode;
    @Field(at = 31, length = 26)
    private String glosaReturn;
    @Field(at = 57, length = 7)
    private String messageLength;
    @Field(at = 64, length = 2)
    private String messageSize;
    @Field(at = 66, length = 2)
    private String appCodeTo;
    @Field(at = 68, length = 1)
    private String institutionCodeTo;
    @Field(at = 69, length = 12)
    private String serviceCodeTo;
    @Field(at = 81, length = 19)
    private String blankSpace;

//    @Segment(at = 100, collection = List.class, minOccurs = 1, maxOccurs = -1, type = CardItemNS67.class)//32160
//    private List<CardItemNS67> cardItemNS67List;


}
