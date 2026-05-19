library(shiny)
library(bslib)

ui <- page_fillable(
  title = "Vorogaze",
  
  theme = bs_theme(
    version = 5,
    base_font_size = "0.9rem",
    "input-font-size" = "0.8rem",
    "input-padding-y" = "0.15rem",
    "input-padding-x" = "0.4rem"
  ),
  
  tags$head(
    tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = "styles.css"
    )
  ),
  
  navset_card_pill(
    
    nav_panel(
      "fixations",
      layout_columns(
        col_widths = c(4, 8),
        
        card(
          card_header("input"),
          # fixation report upload goes here
          card_body(
            div(
              class = "fixrep-upload-box",
              
              fileInput(
                "upload_fixrep",
                "Upload fixation report",
                width = "100%"
              )
            ),
            
            div(
              class = "fixrep-mapping-ui",
              uiOutput("fixrep_mapping_ui")
            )
          )
        ),
        
        layout_columns(
          col_widths = 12,
          
          card(
            card_header("raw"),
            card_body(
              div(
                class = "compact-table-output",
                tableOutput("fixrep_raw_preview")
              )
            )
          ),
          
          card(
            card_header("processed"),
            card_body(
              div(
                class = "compact-table-output",
                tableOutput("fixrep_preview")
              )
            )
          )
        )
      )
    ),
    
    nav_panel(
      "screen",
      layout_columns(
        col_widths = c(4, 8),
        
        card(
          card_header("input"),
          card_body(
            # screen inputs go here
          )
        ),
        
        card(
          card_header("view"),
          card_body(
            # screen view outputs go here
            plotOutput("view_screen")
          )
        )
      )
    ),
    
    nav_panel(
      "images",
      layout_columns(
        col_widths = c(4, 8),
        
        card(
          card_header("input"),
          card_body(
            # image inputs go here
            div(
              class = "face-upload-box",
              
              fileInput(
                "upload_face",
                "Upload face",
                width = "100%"
              )
            )
          )
        ),
        
        card(
          card_header("view"),
          # image view outputs go here
          card_body(
            plotOutput("face_display")
          )
        )
      )
    )
    
    
  )
)