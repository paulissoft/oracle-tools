// https://confluence.jaytaala.com/display/TKB/Super+simple+approach+to+accessing+Spring+beans+from+non-Spring+managed+classes+and+POJOs

package com.paulissoft.pato.jdbc.jmh;

import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.stereotype.Component;
 
@Component
public class SpringContext implements ApplicationContextAware {
     
    private static ApplicationContext context;
     
    /**
     * Returns the Spring managed bean instance of the given class type if it exists.
     * Returns null otherwise.
     */
    public static <T extends Object> T getBean(Class<T> beanClass) {
        return context.getBean(beanClass);
    }
 
    public static Object getBean(String beanName) {
        return context.getBean(beanName);
    }
 
    @SuppressWarnings("NullableProblems")
    @Override
    public void setApplicationContext(ApplicationContext context) throws BeansException {
        // store ApplicationContext reference to access required beans later on
        setContext(context);
    }     
 
    /**
     * Private method context setting (better practice for setting a static field in a bean
     * instance - see comments of this article for more info).
     */
    private static synchronized void setContext(ApplicationContext context) {
        SpringContext.context = context;
    }

    public static ApplicationContext getApplicationContext() {
        return context;
    }
}
