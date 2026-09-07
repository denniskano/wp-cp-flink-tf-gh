package com.bcp.codapp.kafka.connect.smt.model.notification;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

@Getter
@Setter
@ToString
public class Parameter implements Serializable {

    @JsonProperty
    private String key;

    @JsonProperty
    private String value;
}

