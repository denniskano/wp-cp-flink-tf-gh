package com.bcp.codapp.kafka.connect.smt.model.notification;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

@Getter
@Setter
@ToString
public class Attachment implements Serializable {
    @JsonProperty
    private String filename;

    @JsonProperty
    private String data;

    @JsonProperty
    private Extension extension;
}

