package com.bcp.codapp.kafka.connect.smt.util;

public enum AvroObject {
    TAG_REPOSITION_CARD("repositionCard"),
    TAG_CARD("card"),
    TAG_OPERATION("operation"),
    MESSAGE_KEY("messages")
    ;


    private String text;

    AvroObject(String text) {
        this.text = text;
    }

    public String getText() {
        return text;
    }


}

