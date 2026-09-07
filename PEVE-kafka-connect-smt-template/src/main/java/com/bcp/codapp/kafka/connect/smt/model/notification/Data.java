package com.bcp.codapp.kafka.connect.smt.model.notification;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

@Getter
@Setter
@ToString
public class Data implements Serializable {
    @JsonProperty(index = 1)
    private String   customerCic;

    @JsonProperty(index = 2)
    private String   numberOperation;

    @JsonProperty(index = 3)
    private String  requestSend;
}

