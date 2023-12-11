################################################################################
####################### DENV Chile humann mobility #############################
################################################################################

########################### Bernardo Gutierrez #################################

library(tidyverse)
library(janitor)
library(lubridate)
library(stringr)
library(patchwork)
library(NatParksPalettes)

library(seqinr)
library(scales)

############################## Data wrangling ##################################

## Create colour palettes for South American countries ####
latam <- c("Argentina", "Brazil", "Peru", "Uruguay", "Paraguay",
           "Ecuador", "Colombia", "Venezuela", "Bolivia")
latam_palette <- NatParksPalettes$Acadia[1] |> unlist()
names(latam_palette) <- latam

## Import land border crossings (no. of people per month) into Chile ####
# Obtained from the Information Transparency Agency of Chile
# Request placed by Leo Ferres

crossings_raw <- read.csv(
  "data/human_mobility/crossings.csv",
  sep =",")

crossings <- crossings_raw |>
  mutate(value =  as.numeric(gsub(",","",value))) |>
  mutate(commune = stringi::stri_trans_general(commune, "Latin-ASCII")) |>
  mutate(region = stringi::stri_trans_general(region, "Latin-ASCII")) |>
  mutate(region = ifelse(region == "Arica y Parinacota (XV)",
                         "Arica y Parinacota",
                         region)) |>
  mutate(region = ifelse(region == "Antofagasta (II)",
                         "Antofagasta",
                         region)) |>
  mutate(date = case_when(month == "enero" ~ as.Date("2021-01-01"),
                          month == "febrero" ~ as.Date("2021-02-01"),
                          month == "marzo" ~ as.Date("2021-03-01"),
                          month == "abril" ~ as.Date("2021-04-01"),
                          month == "mayo" ~ as.Date("2021-05-01"),
                          month == "junio" ~ as.Date("2021-06-01"),
                          month == " julio" ~ as.Date("2021-07-01"),
                          month == "agosto" ~ as.Date("2021-08-01"),
                          month == "septiembre" ~ as.Date("2021-09-01"),
                          month == "octubre" ~ as.Date("2021-10-01"),
                          month == "noviembre" ~ as.Date("2021-11-01"),
                          month == "diciembre" ~ as.Date("2021-12-01")))

# Create column with cross-border country
for(i in 1:nrow(crossings)){
  crossings$border_with[i] =
    if(crossings$region[i] == "Arica y Parinacota"){
      if(crossings$commune[i] == "Arica"){
        "Peru"
      } else {
        "Bolivia"
      }
    } else if(crossings$region[i] == "Tarapaca"){
      "Bolivia"
    } else if(crossings$region[i] == "Antofagasta"){
      if(crossings$commune[i] == "Ollague"){
        "Bolivia"
      } else {
        "Argentina"
      }
    } else {
      "Argentina"
    }
}

regional_flights <- crossings |> filter(by == "air") |>
  filter(type == "entry") |>
  filter(crossing == "Aeropuerto Chacalluta" |
           crossing == "Aeropuerto Iquique") |>
  select(-type, -by)

regional_ports <- crossings |> filter(by == "sea") |>
  filter(type == "entry") |>
  filter(region == "Arica y Parinacota" |
           region == "Tarapaca") |>
  select(-type, -by)

################################## Plots #######################################

land <- ggplot(crossings |> filter(by == "land") |> filter(type == "entry") |>
                 filter(border_with != "Argentina")) +
  geom_col(aes(x = date, y = value, fill = border_with), position = "dodge") +
  ggtitle("Land") + theme_light() +
  scale_fill_manual(values = c("#d72631", "#5c3c92"),
                    name = "Neighbouring\ncountry") +
  theme(axis.text.x = element_blank()) +
  labs(x = "", y = "")

air <- ggplot(crossings |> filter(by == "air") |> filter(type == "entry") |>
                filter(border_with != "Argentina")) +
  geom_col(aes(x = date, y = value, fill = region), position = "dodge") +
  ggtitle("Air") + theme_light() +
  scale_fill_manual(values = c("#a2d5c6", "#077b8a"),
                    name = "Region") +
  theme(axis.text.x = element_blank()) +
  labs(x = "", y = "Monthly incoming travellers\ninto northern Chile")

sea <- ggplot(crossings |> filter(by == "sea") |> filter(type == "entry") |>
                filter(border_with != "Argentina")) +
  geom_col(aes(x = date, y = value, fill = region), position = "dodge") +
  ggtitle("Sea") + theme_light() +
  scale_fill_manual(values = c("#a2d5c6", "#077b8a")) +
                      theme(legend.position = "none") +
                      labs(x = "", y = "")

land / air / sea

ggsave("north_CL_intl_movements_1.png", bg = "white", dpi = 300,
       height = 7.15, width = 7.15)

a <- ggplot(
  crossings |> filter(border_with == "Peru") |> filter(by == "land") |>
    filter(type == "entry") |>
    select(date, crossing, value) |> group_by(date, crossing) |>
    summarise(total = sum(value))) +
  geom_line(aes(x = date, y = total, color = crossing)) + ggtitle("Peru") +
  theme_light() +
  scale_color_manual(values = c("#3f2965", "#b09ad6"),
                    name = "Border crossing") +
  labs(x = "", y = "")

b <- ggplot(
  crossings |> filter(border_with == "Bolivia") |> filter(by == "land") |>
    filter(type == "entry") |>
    select(date, crossing, value) |> group_by(date, crossing) |>
    summarise(total = sum(value))) +
  geom_line(aes(x = date, y = total, color = crossing)) + ggtitle("Bolivia") +
  theme_light() +
  scale_color_manual(values = c("#8b1820", "#e1515a", "#ed969c", "#f6cbce"),
                    name = "Border crossing") +
  labs(x = "", y = "")

c <- ggplot(regional_flights) +
  geom_line(aes(x = date, y = value, color = crossing, linetype = crossing)) +
  ggtitle("Regional airports") + theme_light() +
  scale_color_manual(values = c("#a2d5c6", "#077b8a"),
                    name = "Airport") +
  scale_linetype_manual(values = c("22", "solid")) +
  guides(linetype = FALSE) +
  labs(x = "", y = "")

d <- ggplot(regional_ports) +
  geom_line(aes(x = date, y = value, color = crossing, linetype = region)) +
  ggtitle("Regional ports") +
  theme_light() +
  scale_color_manual(values = c("#04454e", "#c7e6dc", "#0bbed5"),
                    name = "Port") +
  scale_linetype_manual(values = c("22", "solid"),
                        name = "Region") +
  labs(x = "", y = "")

a / b / c / d

ggsave("north_CL_intl_movements_2.png", bg = "white", dpi = 300,
       height = 7.15, width = 7.15)
ggsave("north_CL_intl_movements_2.pdf", bg = "white", dpi = 300,
       height = 7.15, width = 7.15)
