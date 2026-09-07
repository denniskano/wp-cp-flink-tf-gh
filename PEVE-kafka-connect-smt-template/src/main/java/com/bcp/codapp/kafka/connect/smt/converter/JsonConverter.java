package com.bcp.codapp.kafka.connect.smt.converter;

import com.bcp.codapp.kafka.connect.smt.model.notification.Notification;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import lombok.extern.slf4j.Slf4j;
import org.beanio.StreamFactory;
import org.beanio.internal.util.IOUtil;

import java.io.IOException;
import java.io.InputStream;

@Slf4j
public class JsonConverter {

  private static final StreamFactory stFactory = StreamFactory.newInstance();
  private static final Gson gson = new GsonBuilder().setPrettyPrinting().create();

  private void loadMappingFile(StreamFactory factory, String config) throws IOException {
        Class clas = JsonConverter.class;
        InputStream in = JsonConverter.class.getResourceAsStream(config);
        try {
            factory.load(in);
        } finally {
            IOUtil.closeQuietly(in);
        }
  }


  public static String toJsonFromObject(Notification notification){
        String jsonResult = null;
        jsonResult = gson.toJson(notification);
        return jsonResult;
  }

}

