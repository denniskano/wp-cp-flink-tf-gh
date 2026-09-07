package com.bcp.codapp.kafka.connect.smt.util;


import lombok.extern.slf4j.Slf4j;
import org.beanio.StreamFactory;
import org.beanio.builder.FixedLengthParserBuilder;
import org.beanio.builder.StreamBuilder;

@Slf4j
public class PositionalConverter {

    private PositionalConverter() {
    }

    private static final StreamFactory stFactory = StreamFactory.newInstance();

    /**
     * Get an instance of a certain class, based on a positional string.
     *
     * @param recordSet String of characters.
     * @param target    Class to instance.
     * @param <T>       Generic.
     * @return Populated instance.
     */
    public static <T> T fromPositional(Object recordSet, Class<T> target) {
        String targetName = target.getSimpleName();
        log.debug("FROM POSITIONAL TO {} ", targetName);
        defineInFactoryIfNecessary(targetName, target);
        T result = (T) stFactory.createUnmarshaller(targetName).unmarshal((String)recordSet);
        log.debug("<##> Result *{}*", result);
        return result;
    }

    private static <T> void defineInFactoryIfNecessary(String targetName, Class<T> target) {
        if (!stFactory.isMapped(targetName)) {
            stFactory.define(new StreamBuilder(targetName).format("fixedlength")
                    .parser(new FixedLengthParserBuilder()).addRecord(target));
        }
    }
}

