package com.bcp.codapp.kafka.connect.smt.model;

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
public class DeferredTransfer implements Serializable {

    @Field(at = 160, length = 5)
    private String ttib;

    @Field(at = 165, length = 10)
    private String codPlantilla;

    @Field(at = 175, length = 10)
    private String tipMoneda;

    @Field(at = 185, length = 10)
    private String fecPresentacion;

    @Field(at = 195, length = 10)
    private String horPresentacion;

    @Field(at = 205, length = 10)
    private String numCic;

    @Field(at = 215, length = 8)
    private String numOperacion;

    @Field(at = 223, length = 20)
    private String nomOrdenante;

    @Field(at = 243, length = 20)
    private String codCci;

    @Field(at = 263, length = 20)
    private String nomBeneficiario;

    @Field(at = 283, length = 20)
    private String banDestino;

    @Field(at = 303, length = 20)
    private String importe;

    @Field(at = 323, length = 60)
    private String correo;

}

