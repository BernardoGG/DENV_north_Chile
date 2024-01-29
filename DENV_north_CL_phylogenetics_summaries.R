################################################################################
################### DENV Chile phylogenetic summaries ##########################
################################################################################

########################### Bernardo Gutierrez #################################

library(tidyverse)
library(janitor)
library(lubridate)
library(stringr)
library(patchwork)
library(NatParksPalettes)
library(ape)
library(phylobase)

library(scales)

############################## Data wrangling ##################################
## Create colour palettes for South American countries ####
americas <- c("Argentina", "Brazil", "Peru", "Uruguay", "Paraguay", "Haiti", "Cuba",
              "Ecuador", "Colombia", "Venezuela", "Bolivia", "USA", "Guadeloupe",
              "Dominica", "Martinique", "Puerto_Rico", "Dominican_Republic",
              "Jamaica", "Panama", "Mexico", "Guyana", "Barbados", "Belize",
              "Nicaragua", "Saint_Barthelemy", "Honduras", "El_Salvador", "Grenada",
              "French_Guiana", "Trinidad_and_Tobago", "Suriname", "Guatemala",
              "Saint_Kitts_and_Nevis", "Antigua_and_Barbuda", "Saint_Vincent_and_the_Grenadines")
regions <- c("South America", "Central America", "North America",
             "Caribbean")
serotypes <- c("DENV1", "DENV2", "DENV3", "DENV4")

latam_palette <- NatParksPalettes$Acadia[1] |> unlist()
names(latam_palette) <- latam

regions_palette <- NatParksPalettes$Acadia[1] |> unlist()
names(regions_palette) <- regions

serotypes_palette <- NatParksPalettes$Triglav[1] |> unlist()
serotypes_palette <- serotypes_palette[1:4]
names(serotypes_palette) <- serotypes

## Import (deconstructed) phylogenetic trees and dictionaries ####
# Dictionary for transitions between neighbouring countries
neighbours_dict <- read.csv(
  "analyses/phylogenetics/neighbours_americas.csv",
  sep =",")


d1_nexus <- read.nexus.data("analyses/phylogenetics/DENV1_Americas_timetree.tree")
denv1_americas <- read.nexus("analyses/phylogenetics/DENV1_Americas_timetree.tree")


# Deconstructed phylogenetic trees as data frames
# Generated through custom Python scripts (by Joseph Tsui) from phylogenetic
# pipeline (by Rhys Inward).
denv1_americas_df <- read.csv(
  "analyses/phylogenetics/DENV1_Americas_timetree_df.tsv",
  sep ="\t")

denv2_americas_df <- read.csv(
  "analyses/phylogenetics/DENV2_Americas_timetree_df.tsv",
  sep ="\t")

denv3_americas_df <- read.csv(
  "analyses/phylogenetics/DENV3_Americas_timetree_df.tsv",
  sep ="\t")

denv4_americas_df <- read.csv(
  "analyses/phylogenetics/DENV4_Americas_timetree_df.tsv",
  sep ="\t")

####################### Cross-border viral movements ###########################
## Generate data frame counting viral movements between neighbours ####
# Join serotype data frames
denv_americas_df <- rbind(denv1_americas_df,
                          rbind(denv2_americas_df,
                                rbind(denv3_americas_df, denv4_americas_df))) |>
  mutate(serotype = c(rep("DENV1", nrow(denv1_americas_df)),
                      rep("DENV2", nrow(denv2_americas_df)),
                      rep("DENV3", nrow(denv3_americas_df)),
                      rep("DENV4", nrow(denv4_americas_df))))

# Remove branches with two nodes in the same country
denv_americas_intl <- denv_americas_df |> filter(head_country != tail_country)

# Label individual transitions as 'cross-border' or 'long range'
import_type_vector <- vector()
for(i in 1:nrow(denv_americas_intl)){
  x = ifelse(paste0(denv_americas_intl$head_country[i],
                    denv_americas_intl$tail_country[i])
             %in% paste0(neighbours_dict$origin, neighbours_dict$destination),
             "Cross-border", "Long range")
  import_type_vector = c(import_type_vector, x)
}

denv_americas_intl$import_type = import_type_vector

# Only maintain branches occurring between countries in South America
denv_americas <- denv_americas_intl |> filter(head_country %in% americas &
                                                         tail_country %in% americas)

### Plots
# Plot numbers of international imports by type
plot_data_1 <- denv_americas |>
  mutate(key = paste0(denv_americas$head_country,
                      denv_americas$tail_country)) |>
  group_by(import_type, serotype, key) |>
  summarise(count = n()) |>
#  summarise(proportion = n()) #TODO add proportion of movements from serotype tip numbers
  group_by(import_type) |>
  mutate(sum = sum(count))

ggplot(plot_data_1) + geom_jitter(aes(x = import_type, y = count, color = serotype),
                         size = 2) +
  geom_col(aes(x = import_type, y = sum/1000), alpha = 0.2) +
  scale_y_continuous(sec.axis = sec_axis(~ . *max(plot_data_1$sum)/max(plot_data_1$count),
                                         name = "Total number of inferred transitions")) +
  scale_color_manual(values = serotypes_palette) +
  labs(x = "Import type", y = "No. of movements per country pair",
         color = "Serotype") +
  theme_minimal() +
  theme(axis.text.y.right = element_text(color = "darkred"),
        axis.title.y.right = element_text(color = "darkred"))

# Plot numbers of international imports by serotype
plot_data_2 <- denv_americas_intl |>
  mutate(key = paste0(denv_americas_intl$head_country,
                      denv_americas_intl$tail_country)) |>
  group_by(import_type, serotype, key) |>
  summarise(count = n()) |>
  group_by(import_type, serotype) |>
  mutate(sum = sum(count))

ggplot(plot_data_2) + geom_jitter(aes(x = import_type, y = count, group = serotype)) +
  geom_col(aes(x = import_type, y = sum/3000), alpha = 0.2) +
  facet_wrap(vars(serotype))

# Plot numbers of international imports into Colombia by serotype (example)
plot_data <- denv_americas_intl |>
  mutate(key = paste0(denv_americas_intl$head_country,
                      denv_americas_intl$tail_country)) |>
  group_by(import_type, serotype, key) |>
  summarise(count = n()) |>
  group_by(import_type, serotype) |>
  mutate(sum = sum(count))

ggplot(plot_data) + geom_jitter(aes(x = import_type, y = count, group = serotype)) +
  geom_col(aes(x = import_type, y = sum/3000), alpha = 0.2) +
  facet_wrap(vars(serotype))


################################# Sandbox ######################################
fake_dict <- data.frame(origin = c("country_A", "country_B", "country_C",
                                   "country_D", "country_B", "country_C",
                                   "country_D", "country_E"),
                        destination = c("country_B", "country_C", "country_D",
                                        "country_E", "country_A", "country_B",
                                        "country_C", "country_D"))

denv_americas_intl <- data.frame(head_country = sample(c("country_A", "country_B",
                                                      "country_C","country_D",
                                                      "country_E"),
                                                    500, replace = TRUE),
                                 tail_country = sample(c("country_A", "country_B",
                                                      "country_C","country_D",
                                                      "country_E"),
                                                    500, replace = TRUE),
                                 tail_date = rnorm(500, 2020.3, 1),
                                 serotype = sample(c("DENV 1", "DENV 2",
                                                     "DENV 3","DENV 4"),
                                                   500, replace = TRUE)) |>
  filter(head_country != tail_country)

# Call the function with your tree
country_annotations_phytools <- extract_country_annotations_phytools(denv1_americas)
