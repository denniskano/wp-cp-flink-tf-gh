package com.bcp.codapp.kafka.connect.smt.builder;

import com.bcp.atlas.core.starter.audit.model.avro.AvroAudit;
import com.bcp.codapp.kafka.connect.smt.converter.JsonConverter;
import com.bcp.codapp.kafka.connect.smt.model.DeferredTransfer;
import com.bcp.codapp.kafka.connect.smt.model.notification.*;
import com.bcp.codapp.kafka.connect.smt.util.Constants;
import com.bcp.codapp.kafka.connect.smt.util.PositionalConverter;
import com.bcp.codapp.kafka.connect.smt.util.UUIDUtil;
import com.google.gson.Gson;
import lombok.extern.slf4j.Slf4j;

import java.text.SimpleDateFormat;
import java.util.*;

@Slf4j
public class NotificationBuilder {

    public static AvroAudit buildMessage(String mqMessage) {
        log.info(" MessageBodyBuilder -> buildMessage ");

        Notification notification = (Notification) generateNotificationObject(mqMessage);

        Map<CharSequence, CharSequence> map = new HashMap<>();
        map.put("customerCic", notification.getData().getCustomerCic());
        map.put("numberOperation", notification.getData().getNumberOperation());
        map.put("requestSend", notification.getData().getRequestSend());

        AvroAudit avroAudit = AvroAudit.newBuilder()
                .setEventId(notification.getEventId())
                .setRequestId(notification.getRequestId())
                .setRequestDate(notification.getRequestDate())
                .setChannel(notification.getChannel())
                .setEventType(notification.getEventType())
                .setEntityType(notification.getEntityType())
                .setEntityId(notification.getEntityId())
                .setApplicationGroup(notification.getApplicationGroup())
                .setScopes(Arrays.asList(notification.getScopes()))
                .setResult(notification.getResult())
                .setErrorReason(notification.getErrorReason())
                .setData(map)
                .setExternalData(null)
                .build();

        System.out.println("avroAudit.toString: " + avroAudit.toString());

        return avroAudit;

    }

    public static Object generateNotificationObject(String mqMessage){
        Notification objectResult = new Notification();
        try{
            DeferredTransfer transferencia = PositionalConverter.fromPositional(mqMessage, DeferredTransfer.class);
            fillNotification(objectResult, transferencia);
            log.debug("OBJECT RESULT: {}", objectResult);
        }catch (Exception e){
            log.error("Error generateNotificationObject:", e);
            throw e;
        }
        return objectResult;
    }

    public static String generateNotificationJson(String mqMessage){
        String jsonResult = "";
        Notification notification = new Notification();
        try{
            DeferredTransfer transferencia = PositionalConverter.fromPositional(mqMessage, DeferredTransfer.class);
            fillNotification(notification, transferencia);
            jsonResult = JsonConverter.toJsonFromObject(notification);
            log.debug("OBJECT RESULT: {}", notification);
            log.debug("JSON RESULT: {}", jsonResult);
        }catch (Exception e){
            log.error("Error generateNotificationJson:", e);
            throw e;
        }
        return  jsonResult;
    }

    private static void fillNotification(Notification notification, DeferredTransfer transfer) {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");
        notification.setEventId(UUIDUtil.generateUUID());
        notification.setRequestId(UUIDUtil.generateUUID());
        notification.setRequestDate(sdf.format(new Date()));
        notification.setChannel(Constants.NOTIFICATION_CHANNEL);
        notification.setEventType(Constants.NOTIFICATION_EVENT_TYPE);
        notification.setEntityType(Constants.NOTIFICATION_ENTITY_TYPE);
        notification.setEntityId(transfer.getNumOperacion());
        notification.setApplicationGroup(Constants.NOTIFICATION_APPLICATION_GROUP);
        notification.setScopes(new String[]{Constants.NOTIFICATION_SCOPES});
        notification.setResult(Constants.NOTIFICATION_RESULT);
        notification.setErrorReason(Constants.SPACE);
        Data data = new Data();
        data.setCustomerCic(transfer.getNumCic());
        data.setNumberOperation(transfer.getNumOperacion());
        data.setRequestSend(fillRequestSend(notification, transfer));
        notification.setData(data);
        notification.setExternalData(Constants.BRACKETS);
    }

    private static String fillRequestSend(Notification notification, DeferredTransfer transfer) {
        String requestSend = "";
        RequestSend reqSend = new RequestSend();
        Parameter param = null;
        Destinataries destinataries = new Destinataries();
        destinataries.setTo(new String[]{transfer.getCorreo().trim()});
        reqSend.setDestinataries(destinataries);
        reqSend.setTemplateId(Constants.TEMPLATE_ID);
        Parameter[] parameters = new Parameter[8];

        param = new Parameter();
        param.setKey("p_nombre_ordenante");
        param.setValue(transfer.getNomOrdenante());
        parameters[0]= param;

        param = new Parameter();
        param.setKey("p_nombre_banco_destino");
        param.setValue(transfer.getBanDestino());
        parameters[1]= param;

        param = new Parameter();
        param.setKey("p_codigo_cci");
        param.setValue(transfer.getCodCci());
        parameters[2]= param;

        param = new Parameter();
        param.setKey("p_nombre_beneficiario");
        param.setValue(transfer.getNomBeneficiario());
        parameters[3]= param;

        param = new Parameter();
        param.setKey("p_tipo_moneda");
        param.setValue(transfer.getTipMoneda());
        parameters[4]= param;

        param = new Parameter();
        param.setKey("p_importe");
        param.setValue(transfer.getImporte());
        parameters[5]= param;

        param = new Parameter();
        param.setKey("p_fecha_presentacion");
        param.setValue(transfer.getFecPresentacion());
        parameters[6]= param;

        param = new Parameter();
        param.setKey("p_hora_presentacion");
        param.setValue(transfer.getHorPresentacion());
        parameters[7]= param;
        reqSend.setParameters(parameters);
        return new Gson().toJson(reqSend);
    }


}

