# Event Studies Plots (TWFE)
coefs_twfe = c(dd_plot_reg1$coefficients[22:23],
               0,
               dd_plot_reg1$coefficients[24:29])

se_twfe = c(dd_plot_reg1$se[22:23],
               0,
               dd_plot_reg1$se[24:29])

datos_did_twfe <- data.frame(coeficientes = coefs_twfe, ses = se_twfe, time = -4:4, 
                        type = c(rep(1,3),rep(2,5),rep(1,1)))


datos_did_twfe$time <- factor(datos_did_twfe$time)

colors <- c("#000000","#D55E00")

DID_plot_twfe <- ggplot(data = datos_did_twfe, mapping = aes(y = coeficientes, x = time)) +
  geom_point(aes(colour = factor(type)), size = 2) + 
  geom_errorbar(aes(ymin=(coeficientes-1.96*ses), ymax=(coeficientes+1.96*ses), colour = factor(type)), width=0.2) +
  geom_hline(yintercept = 0, linetype="solid", color ="grey", 2) +
  geom_vline(xintercept = 3,linetype="dashed", color ="red", 2) +
  theme_bw() +
  #labs(subtitle = "Stacked DID") +
  ylab("Valor estimado (95% IC)") + 
  xlab("Semanas desde tratamiento") + 
  ylim(-0.10,0.10) +
  scale_color_manual(name = "Periodo", values= colors) +
  theme(legend.position = "none") 

DID_plot_twfe

# Event studies plots (Stacked DiD)
coefs = c(stacked_time_to_event$coefficients[1:2], 
          0, 
          stacked_time_to_event$coefficients[3:8])

se = c(stacked_time_to_event$se[1:2], 
       0, 
       stacked_time_to_event$se[3:8]) 

datos_did <- data.frame(coeficientes = coefs, ses = se, time = -4:4, 
                        type = c(rep(1,3),rep(2,5),rep(1,1)))

datos_did$time <- factor(datos_did$time)

colors <- c("#000000","#D55E00")

DID_plot2 <- ggplot(data = datos_did, mapping = aes(y = coeficientes, x = time)) +
  geom_point(aes(colour = factor(type)), size = 2) + 
  geom_errorbar(aes(ymin=(coeficientes-1.96*ses), ymax=(coeficientes+1.96*ses), colour = factor(type)), width=0.2) +
  geom_hline(yintercept = 0, linetype="solid", color ="grey", 2) +
  geom_vline(xintercept = 3,linetype="dashed", color ="red", 2) +
  theme_bw() +
  #labs(subtitle = "Stacked DID") +
  ylab("Valor estimado (95% IC)") + 
  xlab("Semanas desde tratamiento") + 
  ylim(-0.80,0.80) +
  scale_color_manual(name = "Periodo", values= colors) +
  theme(legend.position = "none") 

DID_plot2

stacked_time_to_event$coefficients[3:8]