# Coefficients plots
stacked_1 = tibble(type = "STACKED", coef = st1$beta[1],
                   se = st1$cse[1], conf.low = coef - se*1.96, 
                   conf.high = coef + se*1.96)

stacked_1pre = tibble(type = "STACKED PRE", coef = st1_pre$beta[1],
                   se = st1_pre$cse[1], conf.low = coef - se*1.96, 
                   conf.high = coef + se*1.96)

stacked_1post = tibble(type = "STACKED POST", coef = st1_post$beta[1],
                      se = st1_post$cse[1], conf.low = coef - se*1.96, 
                      conf.high = coef + se*1.96)

twfe = tibble(type = "TWFE", coef = -0.015,
              se = 0.008, conf.low = coef - se*1.96, 
              conf.high = coef + se*1.96)

results <- rbind(twfe, stacked_1, stacked_1pre, stacked_1post)

# Graficamos:
results_plot <- ggplot(data = results, aes(x=coef, y=factor(type))) + 
  geom_point() + geom_errorbar(aes(xmin=conf.low, xmax=conf.high)) + 
  geom_vline(xintercept = 0, linetype="solid", color ="black", 3) +
  theme_bw() +  ylab("Estimador") + 
  xlab("Coeficiente estimado (95% IC)") + 
  theme(legend.position = "none") 

results_plot

