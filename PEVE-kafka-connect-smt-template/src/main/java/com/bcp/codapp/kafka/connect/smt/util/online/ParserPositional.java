package com.bcp.codapp.kafka.connect.smt.util.online;


import com.bcp.codapp.kafka.connect.smt.model.online.CardItemNS67;
import lombok.extern.slf4j.Slf4j;
import org.beanio.StreamFactory;
import org.beanio.builder.FixedLengthParserBuilder;
import org.beanio.builder.StreamBuilder;


@Slf4j
public class ParserPositional {

    public ParserPositional() {
    }

    private static StreamFactory factory = StreamFactory.newInstance();


    public static CardItemNS67 parseBodyPositional(Object input) {
        log.info(" { ParserPositional ->  parseBodyPositional }");
        String parseData = input.toString();
        CardItemNS67 cardOperation = ParserPositional.fromPositional(parseData, CardItemNS67.class);
        return cardOperation;
    }


    public static <T> T fromPositional(Object recordSet, Class<T> target) {
        String targetName = target.getSimpleName();
        log.info("FROM POSITIONAL {} ", targetName);
        defineInFactoryIfNecessary(targetName, target);
        T result = (T) factory.createUnmarshaller(targetName).unmarshal((String)recordSet);
        log.info("<##> Result *{}*", result);
        return result;
    }
    private static <T> void defineInFactoryIfNecessary(String targetName, Class<T> target) {
        if (!factory.isMapped(targetName)) {
            factory.define((StreamBuilder)(new StreamBuilder(targetName)).
                    format("fixedlength").parser(new FixedLengthParserBuilder()).addRecord(target));
        }
    }
}

