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
library(RColorBrewer)
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
continental_americas <- c("Argentina", "Brazil", "Peru", "Uruguay", "Paraguay",
                          "Ecuador", "Colombia", "Venezuela", "Bolivia", "USA",
                          "Panama", "Mexico", "Guyana", "Nicaragua", "Honduras",
                          "El_Salvador", "French_Guiana", "Suriname", "Guatemala")
regions <- c("South America", "Central America", "North America",
             "Caribbean")
serotypes <- c("DENV1", "DENV2", "DENV3", "DENV4")

serotypes_palette <- NatParksPalettes$Triglav[1] |> unlist()
serotypes_palette <- serotypes_palette[1:4]
names(serotypes_palette) <- serotypes

continental_americas_palette <- colorRampPalette(NatParksPalettes$Torres[1] |>
                                                   unlist())(length(continental_americas))
names(continental_americas_palette) <- continental_americas

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
denv_americas <- denv_americas_intl |> filter(head_country %in%
                                                continental_americas &
                                                tail_country %in%
                                                continental_americas)

### Plots
# Plot numbers of international imports by serotype
plot_data_1 <- denv_americas |>
  mutate(key = paste0(denv_americas$head_country,
                      denv_americas$tail_country)) |>
  group_by(import_type, serotype, key) |>
  summarise(count = n()) |>
  group_by(import_type, serotype) |>
  mutate(sum = sum(count))

ggplot(plot_data_1) + geom_jitter(aes(x = import_type, y = count,
                                      group = serotype, color = serotype)) +
  geom_col(aes(x = import_type, y = sum/100), alpha = 0.2, fill = "darkgrey") +
  scale_y_continuous(sec.axis = sec_axis(~ . *max(plot_data_2$sum)/max(plot_data_2$count),
                                         name = "Total number of inferred transitions")) +
  facet_wrap(vars(serotype)) +
  scale_color_manual(values = serotypes_palette) +
  labs(x = "Import type", y = "No. of movements per country pair",
       color = "Serotype", title = "Inferred viral movements in continental America") +
  theme_minimal() +
  theme(axis.text.y.right = element_text(color = "darkgrey"),
        axis.title.y.right = element_text(color = "darkgrey"))

# Plot numbers of international imports into specific countries
example_country <- "Colombia"

plot_data_2 <- denv_americas |>
  filter(tail_country == example_country) |>
  group_by(import_type, serotype, head_country) |>
  summarise(count = n())

ggplot(plot_data_2) +
  geom_col(aes(x = count, y = import_type, fill = head_country),
           position = position_dodge2(width = 0.9, preserve = "single")) +
  facet_wrap(vars(serotype), ncol = 1) +
  scale_fill_manual(values = continental_americas_palette) +
  labs(y = "Import type", x = "No. of inferred imports",
       fill = "Source country", title = paste0("DENV imports to ", example_country)) +
  theme_minimal()
