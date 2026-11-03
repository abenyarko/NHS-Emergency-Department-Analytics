# ----------------------------------------
# PCC ER Utilization & Referral Analytics
# Phase 1: GitHub Connection Verification
# ----------------------------------------

# 1. Check Git version
system("git --version")

# 2. Check Git status
system("git status")

# 3. Check GitHub remote connection
system("git remote -v")

# 4. Check current Git branch
system("git branch --show-current")

# 5. Check Git user configuration
system("git config --global user.name")
system("git config --global user.email")

# Configure your Git identity
system('git config --global user.name "Anthony Benyarko"')

# Replace the email below with your GitHub email
system('git config --global user.email "abenyarko@gmail.com"')

# Verify configuration
system("git config --global user.name")
system("git config --global user.email")

folders <- c(
  "R",
  "sql",
  "data",
  "data/synthetic",
  "docs",
  "powerbi",
  "images"
)

invisible(lapply(
  folders,
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))

# Current working directory
getwd()

# Verify project folders
data.frame(
  Folder = folders,
  Exists = dir.exists(folders)
)

# Create a placeholder file in each folder
for (folder in folders) {
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  
  file.create(file.path(folder, ".gitkeep"))
}

# Verify the files exist
list.files(
  recursive = TRUE,
  all.files = TRUE
)

system("git status")
system("git status")

system("git add R/ sql/ data/ docs/ powerbi/ images/")

system('git commit -m "Initialize PCC analytics project folder structure"')

system("git push origin main")

# Check whether Git is ignoring the docs folder
system("git check-ignore -v docs/.gitkeep")

# Check current repository status
system("git status")

# Open the existing .gitignore file
file.edit(".gitignore")


# -------------------------------------------
# PCC ER Utilization & Referral Analytics
# Commit documentation folder to GitHub
# -------------------------------------------

# 1. Stage updated .gitignore and docs folder
system("git add .gitignore docs/.gitkeep")

# 2. Verify staged files
system("git status")

# 3. Commit changes
system('git commit -m "Add documentation folder to project"')

# 4. Push changes to GitHub
system("git push origin main")

# 5. Confirm repository is synchronized
system("git status")



# -------------------------------------------
# PCC ER Utilization & Referral Analytics
# Phase 2: SQLite Environment Setup
# -------------------------------------------

# Install required packages (only needed once)
install.packages(c("DBI", "RSQLite"))

# Load libraries
library(DBI)
library(RSQLite)

# Create a temporary in-memory database
con <- dbConnect(RSQLite::SQLite(), ":memory:")

# Verify SQLite is operational
dbGetQuery(con, "SELECT sqlite_version() AS version")

# Close connection
dbDisconnect(con)


# ---------------------------------------------
# ER Utilization & Referral Analytics
# Phase 2: Permanent SQLite Database Setup
# ---------------------------------------------

library(DBI)
library(RSQLite)

# Verify project working directory
getwd()

# Create directory if needed
dir.create("data", showWarnings = FALSE)

# Define database path
db_path <- "data/er_utilization.sqlite"

# Connect to permanent SQLite database
con <- dbConnect(
  RSQLite::SQLite(),
  dbname = db_path
)

# Enable foreign key enforcement
dbExecute(con, "PRAGMA foreign_keys = ON")

# Verify database connection
dbGetQuery(con, "SELECT sqlite_version() AS version")

# List existing tables
dbListTables(con)

# Confirm database file exists
file.exists(db_path)

dbListTables(con)

file.exists(db_path)

# Close database connection
dbDisconnect(con)


# =====================================================
# ER Utilization & Referral Analytics
# Phase 2: Load and Explore NHS ED Data
# =====================================================

# Load Packages and Libraries

install.packages(c("dplyr", "NHSRdatasets", "tidyverse", "ggplot2", "httr2", "purrr"))
install.packages("httr2")
install.packages("lubridate")
install.packages("rlang", type = "binary")
packageVersion("rlang")
library(dplyr)
library(NHSRdatasets)
library(tidyverse)
library(ggplot2)
library(httr2)
library(httr)
library(purrr)
library("lubridate")


# 1. Load Project Data

# Load NHS Emergency Department data
data(package = "NHSRdatasets")

data("ae_attendances")

# Verify Data Set
View(ae_attendances)

dim(ae_attendances)

names(ae_attendances)


# 2. Initial Data Exploration

str(ae_attendances)

summary(ae_attendances)

head(ae_attendances)

?ae_attendances

levels(ae_attendances$type)

# Missing values
colSums(is.na(ae_attendances))

# Unique Codes
ods_codes <- ae_attendances %>%
  distinct(org_code) %>%
  arrange(org_code)

View(ods_codes)

nrow(ods_codes)

head(ods_codes, 10)


# 3. NHS ODS API Integration

rf4_response <- request(
  "https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations/RF4"
) %>%
  req_perform()

rf4_data <- resp_body_json(rf4_response)

rf4_data

rf4_clean <- tibble(
  org_code = rf4_data$Organisation$OrgId$extension,
  organisation_name = rf4_data$Organisation$Name,
  status = rf4_data$Organisation$Status,
  operational_start = rf4_data$Organisation$Date[[1]]$Start,
  address_1 = rf4_data$Organisation$GeoLoc$Location$AddrLn1,
  address_2 = rf4_data$Organisation$GeoLoc$Location$AddrLn2,
  town = rf4_data$Organisation$GeoLoc$Location$Town,
  postcode = rf4_data$Organisation$GeoLoc$Location$PostCode,
  country = rf4_data$Organisation$GeoLoc$Location$Country
)

rf4_clean


# 4. Provider Linkage & Data Validation


# =====================================================
# SECTION 3: NHS ODS API INTEGRATION
# Function: Retrieve NHS Provider Information
# =====================================================

get_ods_provider <- function(code) {
  
  # Return NA values when a request fails
  empty_record <- tibble(
    org_code = code,
    organisation_name = NA_character_,
    status = NA_character_,
    operational_start = NA_character_,
    address_1 = NA_character_,
    address_2 = NA_character_,
    town = NA_character_,
    postcode = NA_character_,
    country = NA_character_
  )
  
  tryCatch({
    
    response <- httr2::request(
      paste0(
        "https://directory.spineservices.nhs.uk/",
        "ORD/2-0-0/organisations/",
        code
      )
    ) %>%
      httr2::req_timeout(20) %>%
      httr2::req_perform()
    
    org <- httr2::resp_body_json(response)$Organisation
    
    # Safely extract optional fields
    safe_value <- function(x) {
      if (is.null(x) || length(x) == 0) {
        NA_character_
      } else {
        as.character(x[[1]])
      }
    }
    
    location <- org$GeoLoc$Location
    
    operational_dates <- Filter(
      function(x) identical(x$Type, "Operational"),
      org$Date
    )
    
    start_date <- if (length(operational_dates) > 0) {
      safe_value(operational_dates[[1]]$Start)
    } else {
      NA_character_
    }
    
    tibble(
      org_code = code,
      organisation_name = safe_value(org$Name),
      status = safe_value(org$Status),
      operational_start = start_date,
      address_1 = safe_value(location$AddrLn1),
      address_2 = safe_value(location$AddrLn2),
      town = safe_value(location$Town),
      postcode = safe_value(location$PostCode),
      country = safe_value(location$Country)
    )
    
  }, error = function(e) {
    
    warning(
      "ODS lookup failed for ", code, ": ",
      conditionMessage(e)
    )
    
    empty_record
  })
}


test_provider <- get_ods_provider("R1H")

test_provider


ods_test <- map_dfr(
  as.character(head(ods_codes$org_code, 10)),
  get_ods_provider
)

ods_test
View(ods_test)
ods_test %>%
  summarise(
    total_codes = n(),
    matched = sum(!is.na(organisation_name)),
    unmatched = sum(is.na(organisation_name))
  )

ods_reference <- map_dfr(
  as.character(ods_codes$org_code),
  get_ods_provider
)

View(ods_reference)

dim(ods_reference)

ods_reference %>%
  summarise(
    total_codes = n(),
    matched = sum(!is.na(organisation_name)),
    unmatched = sum(is.na(organisation_name)),
    match_rate = matched / total_codes * 100
  )

unmatched_codes <- ods_reference %>%
  filter(is.na(organisation_name))

unmatched_codes

ae_attendances %>%
  filter(org_code %in% c("NLO20", "Y02613")) %>%
  group_by(org_code) %>%
  summarise(
    first_period = min(period),
    last_period = max(period),
    observations = n(),
    total_attendances = sum(attendances),
    total_breaches = sum(breaches),
    total_admissions = sum(admissions)
  )

ae_attendances %>%
  filter(org_code %in% c("NLO20", "Y02613")) %>%
  arrange(org_code, period)

ae_attendances %>%
  mutate(
    ods_matched = !org_code %in% c("NLO20", "Y02613")
  ) %>%
  group_by(ods_matched) %>%
  summarise(
    observations = n(),
    attendances = sum(attendances)
  ) %>%
  mutate(
    pct_attendances = attendances / sum(attendances) * 100
  )

ods_reference %>%
  count(status, sort = TRUE)

# 5. Data Integration

ae_attendances_enriched <- ae_attendances %>%
  mutate(org_code = as.character(org_code)) %>%
  left_join(
    ods_reference,
    by = "org_code"
  )

nrow(ae_attendances)
nrow(ae_attendances_enriched)
names(ae_attendances_enriched)
head(ae_attendances_enriched)

ae_attendances_enriched <- ae_attendances_enriched %>%
  mutate(
    operational_start = as.Date(operational_start)
  )

str(ae_attendances_enriched)


# =====================================================
# SECTION 5A: DATA INTEGRITY VALIDATION
# =====================================================

# Check provider reference uniqueness
duplicate_providers <- ods_reference %>%
  count(org_code) %>%
  filter(n > 1)

print(duplicate_providers)

# Check for duplicated ED reporting keys
duplicate_ed_records <- ae_attendances %>%
  count(period, org_code, type) %>%
  filter(n > 1)

print(duplicate_ed_records)

# Confirm original and enriched record counts
validation_summary <- tibble(
  original_records = nrow(ae_attendances),
  enriched_records = nrow(ae_attendances_enriched),
  unique_providers = n_distinct(
    ae_attendances_enriched$org_code
  ),
  unmatched_records = sum(
    is.na(ae_attendances_enriched$organisation_name)
  )
)

print(validation_summary)

# Check for invalid activity values
invalid_counts <- ae_attendances %>%
  filter(
    attendances < 0 |
      breaches < 0 |
      admissions < 0 |
      breaches > attendances |
      admissions > attendances
  )

print(invalid_counts)

# Stop if key integrity checks fail
stopifnot(
  nrow(duplicate_providers) == 0,
  nrow(duplicate_ed_records) == 0,
  nrow(ae_attendances) ==
    nrow(ae_attendances_enriched),
  nrow(invalid_counts) == 0
)


# =====================================================
# SECTION 5B: INVESTIGATE FLAGGED ACTIVITY RECORD
# =====================================================

# 1. Review all records for provider RTX
rtx_activity <- ae_attendances_enriched %>%
  filter(org_code == "RTX") %>%
  arrange(period, type)

print(rtx_activity, n = Inf)

# 2. Review October 2018 for provider RTX
rtx_oct2018 <- ae_attendances_enriched %>%
  filter(
    org_code == "RTX",
    period == as.Date("2018-10-01")
  ) %>%
  select(
    period,
    org_code,
    organisation_name,
    type,
    attendances,
    breaches,
    admissions
  )

print(rtx_oct2018)

# 3. Review Type 2 admissions exceeding attendances
type2_anomalies <- ae_attendances_enriched %>%
  filter(
    type == "2",
    admissions > attendances
  )

print(type2_anomalies)

# 4. Calculate anomaly magnitude
anomaly_summary <- invalid_counts %>%
  mutate(
    excess_admissions = admissions - attendances,
    admission_rate = admissions / attendances
  )

print(anomaly_summary)

# =====================================================
# SECTION 5B: INVESTIGATE RTX OCTOBER 2018
# =====================================================

rtx_oct2018 <- ae_attendances_enriched %>%
  filter(
    org_code == "RTX",
    period == as.Date("2018-10-01")
  ) %>%
  select(
    period,
    org_code,
    organisation_name,
    type,
    attendances,
    breaches,
    admissions
  )

print(rtx_oct2018, n = Inf)

# =====================================================
# SECTION 5C: ANOMALY ASSESSMENT
# =====================================================

anomaly_summary <- type2_anomalies %>%
  mutate(
    excess_admissions = admissions - attendances,
    admission_rate = if_else(
      attendances > 0,
      admissions / attendances,
      NA_real_
    )
  ) %>%
  select(
    period,
    org_code,
    organisation_name,
    type,
    attendances,
    admissions,
    excess_admissions,
    admission_rate
  )

print(anomaly_summary)

# 6. ED Utilization Metrics

monthly_by_type <- ae_attendances_enriched %>%
  group_by(period, type) %>%
  summarise(
    total_attendances = sum(attendances, na.rm = TRUE),
    total_breaches = sum(breaches, na.rm = TRUE),
    total_admissions = sum(admissions, na.rm = TRUE),
    providers = n_distinct(org_code),
    .groups = "drop"
  ) %>%
  mutate(
    breach_rate = if_else(
      total_attendances > 0,
      total_breaches / total_attendances,
      NA_real_
    ),
    admission_rate = if_else(
      total_attendances > 0,
      total_admissions / total_attendances,
      NA_real_
    ),
    four_hour_performance = 1 - breach_rate
  )
  

View(monthly_by_type)

dim(monthly_by_type)

head(monthly_by_type, 12)

range(monthly_by_type$period)

n_distinct(monthly_by_type$period)

range(monthly_by_type$period)
n_distinct(monthly_by_type$period)
dim(monthly_by_type)
head(monthly_by_type, 12)



print(validation_summary)
print(duplicate_providers)
print(duplicate_ed_records)
print(invalid_counts)


# 7a. Connect to SQLite

# Confirm required objects exist
stopifnot(
  exists("ods_reference"),
  exists("ae_attendances_enriched")
)

# Define database location
dir.create("data", showWarnings = FALSE)

db_path <- "data/er_utilization.sqlite"

# Connect to SQLite
con <- dbConnect(
  RSQLite::SQLite(),
  dbname = db_path
)

# Enable foreign key enforcement
dbExecute(con, "PRAGMA foreign_keys = ON")

# Verify connection
dbGetQuery(
  con,
  "SELECT sqlite_version() AS sqlite_version"
)

dbGetQuery(
  con,
  "PRAGMA foreign_keys"
)

# 7b. Prepare NHS Provider Table

nhs_providers <- ods_reference %>%
  transmute(
    org_code = as.character(org_code),
    organisation_name = as.character(organisation_name),
    status = as.character(status),
    operational_start = as.character(operational_start),
    address_1 = as.character(address_1),
    address_2 = as.character(address_2),
    town = as.character(town),
    postcode = as.character(postcode),
    country = as.character(country)
  )

# Convert missing dates to SQL-compatible NULL
nhs_providers$operational_start[
  is.na(nhs_providers$operational_start)
] <- NA_character_

# Validate provider keys
stopifnot(
  nrow(nhs_providers) == 274,
  !anyNA(nhs_providers$org_code),
  !anyDuplicated(nhs_providers$org_code)
)

print(dim(nhs_providers))
print(head(nhs_providers))


# 7c. Prepare the ED activity table

nhs_ed_activity <- ae_attendances_enriched %>%
  transmute(
    period = as.character(period),
    org_code = as.character(org_code),
    type = as.character(type),
    
    attendances = as.integer(attendances),
    breaches = as.integer(breaches),
    admissions = as.integer(admissions)
    
  )

# Validate source record count
stopifnot(
  nrow(nhs_ed_activity) == 12765
)

# Confirm every ED provider has a reference row
stopifnot(
  all(
    nhs_ed_activity$org_code %in%
      nhs_providers$org_code
  )
)

# Confirm uniqueness of monthly reporting keys
stopifnot(
  !anyDuplicated(
    nhs_ed_activity[
      c("period", "org_code", "type")
    ]
  )
)

print(dim(nhs_ed_activity))
print(head(nhs_ed_activity))


# 7D. Create the relational database tables

# Stop if tables already exist to avoid overwriting data
existing_tables <- dbListTables(con)

stopifnot(
  !("nhs_providers" %in% existing_tables),
  !("nhs_ed_activity" %in% existing_tables)
)

# Create provider reference table
dbExecute(con, "
CREATE TABLE nhs_providers (
  org_code TEXT PRIMARY KEY NOT NULL,
  organisation_name TEXT,
  status TEXT,
  operational_start TEXT,
  address_1 TEXT,
  address_2 TEXT,
  town TEXT,
  postcode TEXT,
  country TEXT
)
")

# Create ED activity table
dbExecute(con, "
CREATE TABLE nhs_er_activity(
  period TEXT NOT NULL,
  org_code TEXT NOT NULL,
  type TEXT NOT NULL,

  attendances INTEGER,
  breaches INTEGER,
  admissions INTEGER,


  PRIMARY KEY (period, org_code, type)

  FOREIGN KEY (org_code)
    REFERENCES nhs_providers(org_code),

  CHECK (type IN ('1', '2', 'other'))

)
")

# Confirm table creation
dbListTables(con)


# 7E. Import the data

# Use a transaction so a failed import rolls back
dbWithTransaction(con, {
  
  dbAppendTable(
    con,
    "nhs_providers",
    nhs_providers
  )
  
  dbAppendTable(
    con,
    "nhs_er_activity",
    nhs_ed_activity
  )
  
})

# Confirm imported record counts
dbGetQuery(con, "
SELECT
  (SELECT COUNT(*) FROM nhs_providers)
    AS provider_records,
  (SELECT COUNT(*) FROM nhs_er_activity)
    AS ed_records
")


# 7F. SQL Database Validation

# 1. Confirm table counts
dbGetQuery(con, "
SELECT
  (SELECT COUNT(*) FROM nhs_providers)
    AS providers,
  (SELECT COUNT(*) FROM nhs_er_activity)
    AS ed_records
")

# 2. Confirm foreign key integrity
dbGetQuery(con, "
PRAGMA foreign_key_check
")


# 4. Verify unmatched provider metadata
dbGetQuery(con, "
SELECT
  org_code,
  organisation_name,
  status
FROM nhs_providers
WHERE organisation_name IS NULL
")

# 5. Verify the RTX anomaly was preserved
dbGetQuery(con, "
SELECT
  period,
  org_code,
  type,
  attendances,
  admissions
FROM nhs_er_activity
WHERE org_code = 'RTX'
  AND period = '2018-10-01'
  AND type = '2'
")

# 6. Test the provider-to-activity join
dbGetQuery(con, "
SELECT
  a.period,
  a.org_code,
  p.organisation_name,
  a.type,
  a.attendances,
  a.admissions
FROM nhs_er_activity AS a
LEFT JOIN nhs_providers AS p
  ON a.org_code = p.org_code
LIMIT 10
")

# 7G. Close Database Connection

dbDisconnect(con)

# Confirm database file exists
file.exists(db_path)

# 7H. Finalize SQLite Database

# Reconnect to the database
con <- dbConnect(
  RSQLite::SQLite(),
  dbname = "data/er_utilization.sqlite"
)

# Enable foreign key enforcement
dbExecute(con, "PRAGMA foreign_keys = ON")

# Confirm the populated table contains all records
stopifnot(
  dbGetQuery(con,
             "SELECT COUNT(*) AS n FROM nhs_er_activity")$n == 12765
)

# Confirm the unused ED table is empty
stopifnot(
  dbGetQuery(con,
             "SELECT COUNT(*) AS n FROM nhs_ed_activity")$n == 0
)

# Delete only the empty table
dbExecute(con, "DROP TABLE nhs_ed_activity")

# Verify remaining tables
dbListTables(con)


# 7I Verify Final Database

# Verify record counts
dbGetQuery(con, "
SELECT
  (SELECT COUNT(*) FROM nhs_providers)
    AS provider_records,
  (SELECT COUNT(*) FROM nhs_er_activity)
    AS er_records
")

# Verify foreign key integrity
dbGetQuery(con, "
PRAGMA foreign_key_check
")

# Verify original RTX values remain unchanged
dbGetQuery(con, "
SELECT
  period,
  org_code,
  type,
  attendances,
  breaches,
  admissions
FROM nhs_er_activity
WHERE org_code = 'RTX'
  AND period = '2018-10-01'
  AND type = '2'
")

# Close the connection
dbDisconnect(con)


# =====================================================
# SECTION 8A: EXECUTE NATIONAL ED UTILIZATION SQL
# =====================================================


# Connect to SQLite
con <- dbConnect(
  RSQLite::SQLite(),
  dbname = "data/er_utilization.sqlite"
)

# Query 1: Overall utilization
national_utilization <- dbGetQuery(con, "
SELECT
    COUNT(*) AS reporting_records,
    COUNT(DISTINCT org_code) AS total_providers,
    MIN(period) AS first_month,
    MAX(period) AS last_month,
    SUM(attendances) AS total_attendances,
    SUM(breaches) AS total_breaches,
    SUM(admissions) AS total_admissions,
    ROUND(
        100.0 * SUM(breaches) /
        NULLIF(SUM(attendances), 0), 2
    ) AS breach_rate_pct,
    ROUND(
        100.0 * SUM(admissions) /
        NULLIF(SUM(attendances), 0), 2
    ) AS admission_rate_pct
FROM nhs_er_activity
")

print(national_utilization)

# Query 2: Utilization by department type
utilization_by_type <- dbGetQuery(con, "
SELECT
    type AS department_type,
    COUNT(*) AS reporting_records,
    COUNT(DISTINCT org_code) AS providers,
    SUM(attendances) AS total_attendances,
    SUM(breaches) AS total_breaches,
    SUM(admissions) AS total_admissions,
    ROUND(
        100.0 * SUM(breaches) /
        NULLIF(SUM(attendances), 0), 2
    ) AS breach_rate_pct,
    ROUND(
        100.0 * SUM(admissions) /
        NULLIF(SUM(attendances), 0), 2
    ) AS admission_rate_pct
FROM nhs_er_activity
GROUP BY type
ORDER BY
    CASE type
        WHEN '1' THEN 1
        WHEN '2' THEN 2
        ELSE 3
    END
")

print(utilization_by_type)

# Validate expected record counts
stopifnot(
  national_utilization$reporting_records == 12765,
  national_utilization$total_providers == 274,
  nrow(utilization_by_type) == 3
)

# Close connection
dbDisconnect(con)

source_totals <- ae_attendances %>%
  summarise(
    total_attendances = sum(attendances, na.rm = TRUE),
    total_breaches = sum(breaches, na.rm = TRUE),
    total_admissions = sum(admissions, na.rm = TRUE)
  )

print(source_totals)

stopifnot(
  source_totals$total_attendances ==
    national_utilization$total_attendances,
  source_totals$total_breaches ==
    national_utilization$total_breaches,
  source_totals$total_admissions ==
    national_utilization$total_admissions
)


# 8B. Monthly Trends Analysis

con <- dbConnect(
  RSQLite::SQLite(),
  dbname = "data/er_utilization.sqlite"
)

monthly_trends <- dbGetQuery(con, "
SELECT
    period AS reporting_month,
    SUM(attendances) AS total_attendances,
    SUM(breaches) AS total_breaches,
    SUM(admissions) AS total_admissions,
    ROUND(
      100.0 * SUM(breaches) /
      NULLIF(SUM(attendances), 0), 2
    ) AS breach_rate_pct,
    ROUND(
      100.0 * SUM(admissions) /
      NULLIF(SUM(attendances), 0), 2
    ) AS admission_rate_pct
FROM nhs_er_activity
GROUP BY period
ORDER BY period
")

dbDisconnect(con)

# Convert reporting month to Date
monthly_trends <- monthly_trends %>%
  mutate(reporting_month = as.Date(reporting_month))

# Validate the 36-month reporting period
stopifnot(
  nrow(monthly_trends) == 36,
  sum(monthly_trends$total_attendances) == 72019402,
  sum(monthly_trends$total_breaches) == 8295237,
  sum(monthly_trends$total_admissions) == 13493280
)

# Inspect results
print(monthly_trends)

monthly_trends <- monthly_trends %>%
  mutate(
    days_in_month = days_in_month(reporting_month),
    average_daily_attendances =
      total_attendances / days_in_month
  )

# Identify the highest and lowest months
monthly_trends %>%
  arrange(desc(average_daily_attendances)) %>%
  select(
    reporting_month,
    total_attendances,
    average_daily_attendances
  ) %>%
  as_tibble() %>%
  print(n = 36)

# Plot monthly attendance trends
library(scales)

ggplot(
  monthly_trends,
  aes(
    x = reporting_month,
    y = average_daily_attendances
  )
) +
  geom_line(color = "#2563EB", linewidth = 1) +
  geom_point(color = "#2563EB", size = 1.5) +
  
  # Display month and year every 3 months
  scale_x_date(
    date_breaks = "3 months",
    date_labels = "%b %Y"
  ) +
  
  # Format Y-axis
  scale_y_continuous(
    labels = scales::label_comma()
  ) +
  
  labs(
    title = "Average Daily NHS ED Attendances",
    subtitle = "April 2016 - March 2019",
    x = "Reporting Month",
    y = "Average Daily Attendances",
    caption = "Source: NHSRdatasets | Historical aggregate data"
  ) +
  
  theme_minimal() +
  
  # Rotate X-axis labels for readability
  theme(
    axis.text.x = element_text(
      angle = 45,
      hjust = 1,
      size = 9
    ),
    plot.title = element_text(face = "bold")
  )


# 8C. Provider-Level Analysis

con <- dbConnect(
  RSQLite::SQLite(),
  dbname = "data/er_utilization.sqlite"
)

provider_performance <- dbGetQuery(con, "
SELECT
    e.org_code,
    COALESCE(
        p.organisation_name,
        'Provider name unavailable'
    ) AS organisation_name,
    COUNT(DISTINCT e.period) AS reporting_months,
    SUM(e.attendances) AS total_attendances,
    SUM(e.breaches) AS total_breaches,
    SUM(e.admissions) AS total_admissions,
    ROUND(
        100.0 * SUM(e.breaches) /
        NULLIF(SUM(e.attendances), 0), 2
    ) AS breach_rate_pct,
    ROUND(
        100.0 * SUM(e.admissions) /
        NULLIF(SUM(e.attendances), 0), 2
    ) AS admission_rate_pct
FROM nhs_er_activity AS e
LEFT JOIN nhs_providers AS p
    ON e.org_code = p.org_code
GROUP BY
    e.org_code,
    p.organisation_name
ORDER BY total_attendances DESC
")

dbDisconnect(con)

# Verify provider coverage and totals
stopifnot(
  nrow(provider_performance) == 274,
  sum(provider_performance$total_attendances) == 72019402,
  sum(provider_performance$total_breaches) == 8295237,
  sum(provider_performance$total_admissions) == 13493280
)

# Display the 10 highest-volume providers
provider_performance %>%
  slice_max(
    order_by = total_attendances,
    n = 10
  ) %>%
  as_tibble() %>%
  print(n = 10)

# Check provider reporting coverage
provider_performance %>%
  count(reporting_months, name = "providers") %>%
  arrange(desc(reporting_months)) %>%
  print()


# =====================================================
# SECTION 8C: TOP AND BOTTOM PROVIDER RANKINGS
# =====================================================


provider_rankings <- provider_performance %>%
  mutate(
    average_monthly_attendances =
      total_attendances / reporting_months
  ) %>%
  filter(
    reporting_months == 36,
    total_attendances > 0
  )

# Top 10 providers
top_10_providers <- provider_rankings %>%
  arrange(desc(average_monthly_attendances)) %>%
  slice_head(n = 10)

# Bottom 10 providers
bottom_10_providers <- provider_rankings %>%
  arrange(average_monthly_attendances) %>%
  slice_head(n = 10)

# View results
top_10_providers %>%
  select(
    organisation_name,
    reporting_months,
    average_monthly_attendances
  ) %>%
  as_tibble() %>%
  print(n = 10)

bottom_10_providers %>%
  select(
    organisation_name,
    reporting_months,
    average_monthly_attendances
  ) %>%
  as_tibble() %>%
  print(n = 10)


# Check the current GitHub connection
system("git remote -v")


# Update GitHub repository connection
system(
  "git remote set-url origin https://github.com/abenyarko/NHS-Emergency-Department-Analytics"
)

# Verify the new connection
system("git remote -v")


# Check repository status
system("git status")

# Verify GitHub can be reached
system("git ls-remote origin HEAD")


# Add SQLite files to .gitignore
cat(
  "\n# Local SQLite databases\n",
  "data/*.sqlite\n",
  "data/*.sqlite-journal\n",
  "data/*.sqlite-wal\n",
  "data/*.sqlite-shm\n",
  file = ".gitignore",
  append = TRUE
)

# Verify the database is ignored
system("git check-ignore data/er_utilization.sqlite")


# Show all modified and untracked files
system("git status --short")


# Read the current .gitignore file
readLines(".gitignore")


# Read existing .gitignore
ignore_lines <- readLines(".gitignore")

# Remove leading spaces from SQLite rules
ignore_lines <- sub(
  "^\\s+(data/\\*\\.sqlite.*)$",
  "\\1",
  ignore_lines
)

# Save the corrected file
writeLines(ignore_lines, ".gitignore")

# Verify the SQLite database is ignored
system("git check-ignore -v data/er_utilization.sqlite")

# Check repository status
system("git status --short")


# Stage updated .gitignore
system("git add .gitignore")

# Commit the change
system(
  'git commit -m "Update Git ignore rules for NHS ED analytics"'
)

# Push to the renamed GitHub repository
system("git push origin main")

# Verify synchronization
system("git status")


# Download the latest GitHub history
system("git fetch origin")

# Check synchronization status
system("git status")

# See differences between local and remote commits
system("git log --oneline --left-right HEAD...origin/main")


# Reapply your local commit after the remote commits
system("git pull --rebase origin main")


# Upload your local commit
system("git push origin main")

# Confirm synchronization
system("git status")

# Review latest commit
system("git log -1 --oneline")


# List files in the R and SQL folders
list.files("R", all.files = TRUE)
list.files("sql", all.files = TRUE)

# Confirm the active project directory
getwd()


# Find R scripts in the current project
list.files(
  path = ".",
  pattern = "\\.[Rr]$",
  recursive = TRUE,
  full.names = TRUE
)

# Check your current RStudio open files
if (requireNamespace("rstudioapi", quietly = TRUE)) {
  rstudioapi::documentPath()
}
