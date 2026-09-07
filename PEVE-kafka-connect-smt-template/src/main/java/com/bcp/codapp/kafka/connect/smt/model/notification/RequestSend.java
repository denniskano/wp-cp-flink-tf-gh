package com.bcp.codapp.kafka.connect.smt.model.notification;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

@Getter
@Setter
@ToString
@JsonInclude(JsonInclude.Include.NON_NULL)
public class RequestSend implements Serializable {
    @JsonProperty
    private Destinataries destinataries;

    @JsonProperty
    private Message message;

    @JsonProperty
    private String templateId;

    @JsonProperty
    private Parameter[] parameters;
}

