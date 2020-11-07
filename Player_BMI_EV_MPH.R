#Loading in Libraries
library(tidyverse)
library(Lahman)
library(sqldf)
library(gridExtra)
library(ggthemes)

#Loading in Data from Personal Savant Database (Details on this in README)
pitcher_data<-read.csv('~/Downloads/pitcher_data_bmi_project.csv')

hitter_data<-read.csv('~/Downloads/hitter_data_bmi_project.csv')

lahman_player_data<-Master %>%
  select (playerID, height, weight)

player_id_mapping<-read.delim('http://crunchtimebaseball.com/master.txt')
player_id_mapping<-player_id_mapping %>%
  select(mlb_id, mlb_pos, lahman_id) 

#Creating Pitcher and Hitter tables/Joining height and weight data
##I like to use the sqldf package for joins as a preference/comfortability
pitcher_data<-sqldf('SELECT pitcher_data.*, player_id_mapping.lahman_id, player_id_mapping.mlb_pos
                    FROM pitcher_data
                    JOIN player_id_mapping
                    ON pitcher_data.pitcher_id=player_id_mapping.mlb_id')
pitcher_data<-sqldf('SELECT pitcher_data.*, lahman_player_data.height, lahman_player_data.weight
                    FROM pitcher_data
                    JOIN lahman_player_data
                    ON pitcher_data.lahman_id=lahman_player_data.playerID')
pitcher_data$lahman_id<-NULL


hitter_data<-sqldf('SELECT hitter_data.*, player_id_mapping.lahman_id, player_id_mapping.mlb_pos
                    FROM hitter_data
                   JOIN player_id_mapping
                   ON hitter_data.batter_id=player_id_mapping.mlb_id')
hitter_data<-sqldf('SELECT hitter_data.*, lahman_player_data.height, lahman_player_data.weight
                    FROM hitter_data
                   JOIN lahman_player_data
                   ON hitter_data.lahman_id=lahman_player_data.playerID')
hitter_data$lahman_id<-NULL

#Adding in BMI Column
pitcher_data<- pitcher_data %>%
  mutate(BMI=round(703*weight/(height^2),1)) %>%
  filter(avg_velocity>80, number_of_pitches>=100)

hitter_data<-hitter_data %>%
  mutate(##Adding in weight for Jacob Stallings as Lahman has him weighing 76lbs##
         weight=ifelse(weight==76,220,weight),
         BMI=round(703*weight/(height^2),1)) %>%
  filter(mlb_pos!='P', number_of_batted_balls>50)

#Creating Summary Tables for Hitter/Pitcher BMI's
hitter_bmi_summary<-hitter_data %>%
  mutate(BMI=round(BMI,0)) %>%
  select(max_ev, avg_ev, avg_la, BMI)
hitter_bmi_summary<-sqldf('SELECT ROUND(AVG(max_ev),2) AS avg_max_ev, ROUND(AVG(avg_ev),2) AS avg_ev, ROUND(AVG(avg_la),2) AS avg_la, BMI, COUNT(*) AS number_of_players, (COUNT(*)*100/(SELECT Count(*) FROM hitter_bmi_summary)) as percentage_of_total
                          FROM hitter_bmi_summary
                          GROUP BY BMI')

pitcher_bmi_summary<-pitcher_data %>%
  mutate(BMI=round(BMI,0)) %>%
  select(avg_velocity, max_velocity, BMI)
pitcher_bmi_summary<-sqldf('SELECT ROUND(AVG(max_velocity),2) AS avg_max_velocity, ROUND(AVG(avg_velocity),2) AS avg_velocity, BMI, COUNT(*) AS number_of_players, (COUNT(*)*100/(SELECT Count(*) FROM pitcher_bmi_summary)) as percentage_of_total
                           FROM pitcher_bmi_summary
                           GROUP BY BMI')

#BMI Graphs

##Bar Charts
hitter_bmi_graph<-hitter_bmi_summary %>%
  filter(percentage_of_total>0)%>%
  ggplot(hitter_bmi_summary, mapping=aes(x=BMI, y=percentage_of_total))+
  geom_col(fill='dark red')+
  scale_x_continuous(breaks = seq(19, 40, 1))+
  xlab(label='BMI (Bar Label=Average Exit Velocity)')+
  ylab(label='Percentage of Total')+
  ggtitle('Hitter BMI Distribution') +
  geom_text(aes(label=avg_ev), vjust=-0.5)+
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        axis.title = element_text(size=15))
###hitter_bmi_graph

pitcher_bmi_graph<-pitcher_bmi_summary 
  filter(percentage_of_total>0) %>%
  ggplot(pitcher_bmi_summary, mapping=aes(x=BMI, y=percentage_of_total))+
  geom_col(fill='dark red')+
  scale_x_continuous(breaks = seq(19, 40, 1))+
  xlab('BMI (Bar Label=Average Pitch Velocity)')+
  ylab('Percentage of Total Sample')+
  ggtitle('Pitcher BMI Distribution') +
  geom_text(aes(label=avg_velocity), vjust=-0.5)+
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        axis.title = element_text(size=15))
###pitcher_bmi_graph

grid.arrange(hitter_bmi_graph, pitcher_bmi_graph)

##Scatter Plots
summary(lm(avg_ev~weight,hitter_data))$r.squared

ev_bmi_plot<-
  ggplot(hitter_data, mapping=aes(x=BMI, y=avg_ev))+
  geom_point()+
  ylab('Average Exit Velocity')+
  geom_smooth(method = 'lm')+
  ggtitle('BMI vs. Average Exit Velocity')+
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        axis.title = element_text(size=15))+
  geom_text(x=22.5, y=100, label='r^2=0.08', size=10)
ev_bmi_plot

ev_weight_plot<-
  ggplot(hitter_data, mapping=aes(x=BMI, y=avg_ev))+
  geom_point()+
  ylab('Average Exit Velocity')+
  geom_smooth(method = 'lm')+
  ggtitle('Weight vs. Average Exit Velocity')+
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        axis.title = element_text(size=15))+
  geom_text(x=35, y=82.5, label='r^2=0.25', size=10)
ev_weight_plot

summary(lm(avg_velocity~BMI,pitcher_data))$r.squared

pitch_velo_bmi_plot<-
  ggplot(pitcher_data, mapping=aes(x=BMI, y=avg_velocity))+
  geom_point()+
  ylab('Average Pitch Velocity')+
  geom_smooth(method = 'lm')+
  ggtitle('BMI vs. Average Pitch Velocity')+
  theme(plot.title = element_text(hjust = 0.5, size = 20),
        axis.title = element_text(size=15))+
  geom_text(x=37.5, y=85, label='r^2=0.009', size=10)
pitch_velo_bmi_plot


y<-c(3,5.236,7.472,9.708)
x<-c(1,2,3,4)
ab<-data.frame(y,x)
ab <- ab%>%
  mutate(c=y-2*x)
sapply(ab,var)