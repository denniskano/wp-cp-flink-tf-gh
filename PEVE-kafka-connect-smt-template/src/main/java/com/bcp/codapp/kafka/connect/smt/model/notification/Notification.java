package com.bcp.codapp.kafka.connect.smt.model.notification;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

@Getter
@Setter
@ToString
public class Notification implements Serializable {
    @JsonProperty(index = 1)
    private String eventId;

    @JsonProperty(index = 2)
    private String requestId;

    @JsonProperty(index = 3)
    private String requestDate;

    @JsonProperty(index = 4)
    private String channel;

    @JsonProperty(index = 5)
    private String eventType;

    @JsonProperty(index = 6)
    private String entityType;

    @JsonProperty(index = 7)
    private String entityId;

    @JsonProperty(index = 8)
    private String applicationGroup;

    @JsonProperty(index = 9)
    private String[] scopes;

    @JsonProperty(index = 10)
    private String result;

    @JsonProperty(index = 11)
    private String errorReason ;

    @JsonProperty(index = 12)
    private Data data;

    @JsonProperty(index = 13)
    private String externalData;

}

