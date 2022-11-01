/*[% EDSLANG = {
    home_breadcrumb    									= 'Home'
	eds_results_TT_no_results   						= 'No results found!'
	eds_results_TT_results_returned_msg					= 'Your search returned'
    eds_results_TT_results_msg							= 'results.'
    eds_results_TT_did_you_mean							= 'Did you mean:'
    eds_results_TT_correction						    = 'Your search was corrected to:'
    eds_results_TT_title_attr							= 'View details for this title'
    eds_results_TT_links								= 'Links:'
    eds_results_TT_links_html							= 'HTML Full Text'
    eds_results_TT_links_pdf							= 'PDF Full Text'
    eds_results_TT_links_ebook							= 'eBook Full Text'
    eds_results_TT_links_other                          = 'Linked Full Text'
    eds_results_TT_actions								= 'Actions:'
    eds_results_TT_place_reserve						= 'Place reserve'
    eds_results_TT_save_to_list							= 'Save to Lists'
    eds_results_TT_in_cart								= 'In your cart'
    eds_results_TT_remove_cart							= '(remove)'
    eds_results_TT_add_cart								= 'Add to cart'
	eds_results_TT_login_msg							= 'Login to gain access to this result.'
    eds_results_TT_annosuggestions						= 'Not finding what you\'re looking for?'
    eds_results_TT_annosuggestions_makea				= 'Make a'
    eds_results_TT_annosuggestions_purchase				= 'purchase suggestion'
    eds_results_TT_quickview_login                      = 'Login to see attached images'

	eds_detail_TT_details_for							= 'Details for:'
	eds_detail_TT_normal_view							= 'Normal view:'
	eds_detail_TT_login_msg								= 'Login to gain access to this result.'
    eds_detail_TT_quickview_login                       = 'Login to see attached images'

    eds_detail_customlinks_INC_html_fulltext			= 'HTML Full Text'
    eds_detail_customlinks_INC_pdf_fulltext				= 'PDF Full Text'
    eds_detail_customlinks_INC_ebook_fulltext			= 'eBook Full Text'
    eds_detail_customlinks_INC_view_in_eds				= 'View in EDS'
    eds_detail_customlinks_INC_other                    = 'Linked Full Text'

    eds_detail_sidebar_INC_print						= 'Print'
    eds_detail_sidebar_INC_in_cart						= 'In your cart'
    eds_detail_sidebar_INC_remove_cart					= '(remove)'
    eds_detail_sidebar_INC_add_cart						= 'Add to your cart'

	eds_advsearch_TT_breadcrumb_home					= 'Home'
    eds_advsearch_TT_breadcrumb_advanced_search			= 'Advanced search'
    eds_advsearch_TT_select_field						= 'Select a Field (optional)'
	eds_advsearch_TT_bool_and							= 'AND'
	eds_advsearch_TT_bool_or							= 'OR'
	eds_advsearch_TT_bool_not							= 'NOT'
    eds_advsearch_TT_opt_add							= 'Add'
    eds_advsearch_TT_opt_remove							= 'Remove'
    eds_advsearch_TT_search_options						= 'Search Options'
    eds_advsearch_TT_search_opt_heading					= 'Search Modes and Expanders'
    eds_advsearch_TT_search_opt_modes					= 'Search modes'
    eds_advsearch_TT_search_help_title					= 'Enter as much text for your search as you want - a phrase, a sentence, paragraph, or even whole pages. This mode searches EBSCO Databases only.'
    eds_advsearch_TT_search_help						= 'Hint'
    eds_advsearch_TT_limit_legend						= 'Limit your results'
	eds_advsearch_TT_date_month							= 'Month'
	eds_advsearch_TT_date_month_jan						= 'January'
    eds_advsearch_TT_date_month_feb						= 'February'
    eds_advsearch_TT_date_month_mar						= 'March'
    eds_advsearch_TT_date_month_apr						= 'April'
    eds_advsearch_TT_date_month_may						= 'May'
    eds_advsearch_TT_date_month_jun						= 'June'
    eds_advsearch_TT_date_month_jul						= 'July'
    eds_advsearch_TT_date_month_aug						= 'August'
    eds_advsearch_TT_date_month_sep						= 'September'
    eds_advsearch_TT_date_month_oct						= 'October'
    eds_advsearch_TT_date_month_nov						= 'November'
    eds_advsearch_TT_date_month_dec						= 'December'
    eds_advsearch_TT_date_year							= 'Year:'
    eds_advsearch_TT_btn_search							= 'Search'
    eds_advsearch_TT_btn_reset							= 'Reset'



    eds_facets_INC_refine_search						= 'Refine your search'
    eds_facets_INC_current_search						= 'Current Search'
	eds_facets_INC_search_term							= 'Search Term(s)'
    eds_facets_INC_active_facets						= 'Active Facets'
    eds_facets_INC_limit_to								= 'Limit To:'
    eds_facets_INC_expand_to							= 'Expand To:'

    eds_page_numbers_INC_previous						= 'Previous'
    eds_page_numbers_INC_next 							= 'Next'

    eds_publicationexactmatch_INC_full_text_access		= 'Full Text Access'
    eds_publicationexactmatch_INC_search_within			= 'Search within Publication'

    eds_researchstarters_INC_more						= 'More.'

    eds_resort_form_INC_results_per_page				= 'Results per page:'
    eds_resort_form_INC_view							= 'View:'
    eds_resort_form_INC_view_title						= 'Title'
    eds_resort_form_INC_view_brief						= 'Brief'
    eds_resort_form_INC_view_detail						= 'Detailed'
    eds_resort_form_INC_search_mode						= 'Search mode:'
    eds_resort_form_INC_sort_by							= 'Sort by:'

    eds_metadata_Authors                                = 'Authors'
    eds_metadata_Source                                 = 'Source'
    eds_metadata_Subject_Terms                          = 'Subject Terms'
    eds_metadata_Geographic_Terms                       = 'Geographic Terms'
    eds_metadata_Time                                   = 'Time'
    eds_metadata_Availability                           = 'Availability'
    eds_metadata_File_Description                       = 'File Description'
    eds_metadata_Relation                               = 'Relation'
    eds_metadata_Access_URL                             = 'Access URL'
    eds_metadata_Publication_Information                = 'Publication Information'
    eds_metadata_Document_Type                          = 'Document Type'
    eds_metadata_Author_Supplied_Keywords               = 'Author-Supplied Keywords'
    eds_metadata_Language_of_Keywords                   = 'Language of Keywords'
    eds_metadata_NAICS_Industry_Codes                   = 'NAICS/Industry Codes'
    eds_metadata_Abstract_English                       = 'Abstract (English)'
    eds_metadata_Abstract_German                        = 'Abstract (German)'
    eds_metadata_Accession_Number                       = 'Accession Number'
    eds_metadata_Publication_Type                       = 'Publication Type'
    eds_metadata_Other_Authors                          = 'Other Authors'
    eds_metadata_Online_Access                          = 'Online Access'
    eds_metadata_MeSH_Terms                             = 'MeSH Terms'
    eds_metadata_Journal_Info                           = 'Journal Info'
    eds_metadata_Major_Subjects                         = 'Major Subjects'
    eds_metadata_Minor_Subjects                         = 'Minor Subjects'
    eds_metadata_Language                               = 'Language'
    eds_metadata_Imprint_Names                          = 'Imprint Name(s)'
    eds_metadata_Abstract                               = 'Abstract'
    eds_metadata_References                             = 'References'
    eds_metadata_Contributed_Indexing                   = 'Contributed Indexing'
    eds_metadata_Substance_Nomenclature                 = 'Substance Nomenclature'
    eds_metadata_Entry_Dates                            = 'Entry Date(s)'
    eds_metadata_Update_Code                            = 'Update Code'

    eds_facets_Source_Type                               = 'Source Type'
    eds_facets_Language                                  = 'Language'
    eds_facets_Lexile_Range                              = 'Lexile Range'
    eds_facets_Publisher                                 = 'Publisher'
    eds_facets_Publication                               = 'Publication'
    eds_facets_Geography                                 = 'Geography'
    eds_facets_Category                                  = 'Category'
    eds_facets_Collection                                = 'Collection'
    eds_facets_Publication_Year                          = 'Publication Year'
    eds_facets_Deskriptoren                              = 'Deskriptoren'
    eds_facets_Content_Provider                          = 'Content Provider'
    
    eds_expander_thesaurus                              = 'Apply related words'
    eds_expander_fulltext                               = 'Also search within the full text of the articles'
    eds_expander_relatedsubjects                        = 'Apply equivalent subjects'

    eds_limiter_FT                                      = 'Full Text'
    eds_limiter_FR                                      = 'References Available'
    eds_limiter_RV                                      = 'Peer Reviewed'
    eds_limiter_FT1                                     = 'Available in Library Collection'
    eds_limiter_FC                                      = 'Catalog Only'
    eds_limiter_DT1                                     = 'Published Date'

    eds_resort_form_relevance                           = 'Relevance'
    eds_resort_form_date                                = 'Date Newest'
    eds_resort_form_date2                               = 'Date Oldest'
    eds_resort_form_bool                                = 'Boolean/Phrase'
    eds_resort_form_all                                 = 'Find all my search terms'
    eds_resort_form_any                                 = 'Find any of my search terms'
    eds_resort_form_smart                               = 'SmartText Searching'

    eds_pubtypes_serialPeriodical                       = 'Periodical' 
    eds_pubtypes_newspaperArticle                       = 'Newspaper'
    eds_pubtypes_image                                  = 'Image'
    eds_pubtypes_videoRecording                         = 'Video'
    eds_pubtypes_score                                  = 'Music Score'
    eds_pubtypes_audio                                  = 'Audio'
    eds_pubtypes_map                                    = 'Map'
    eds_pubtypes_book                                   = 'Book'
    eds_pubtypes_kitObject                              = 'Kit/Object'
    eds_pubtypes_academicJournal                        = 'Academic Journal'
    eds_pubtypes_dissertation                           = 'Dissertation'
    eds_pubtypes_literaryMaterial                       = 'Literatry Work'
    eds_pubtypes_tableChart                             = 'Table or Chart'
    eds_pubtypes_patent                                 = 'Patent'
    eds_pubtypes_report                                 = 'Report'
    eds_pubtypes_reference                              = 'Reference' 
    eds_pubtypes_governmentDocument                     = 'Government Document'
    eds_pubtypes_editorialOpinion                       = 'Commentary, Editorial'
    eds_pubtypes_transcript                             = 'Transcript'
    eds_pubtypes_review                                 = 'Review'
    eds_pubtypes_biography                              = 'Biography'
    eds_pubtypes_electronicResource                     = 'eBook'
    eds_pubtypes_featureArticle                         = 'Feature Article'
    eds_pubtypes_series                                 = 'Periodical'
    eds_pubtypes_ebook                                  = 'eBook'
    eds_pubtypes_audiobook                              = 'Audio Book'
    eds_pubtypes_conference                             = 'Conference Proceeding'
    eds_pubtypes_Poem                                   = 'Poem'
    eds_pubtypes_ShortStory                             = 'Short Story'
    eds_pubtypes_play                                   = 'Play'
}%]*/
var EDSLANG = {
	eds_koha_lang_id									: 'default',
	eds_koha_language									: '[%lang%]',
	eds_switch_text										: 'Switch to Discovery',
	koha_switch_text									: 'Switch to Catalogue',
	eds_select_text										: "Discovery",
	koha_select_text                                    : 'Catalogue',
	eds_select_info										: '<h3>Search EDS</h3>Select a known item and enter a search term',
	koha_select_info									: '<h3>Search Koha</h3>Select a known item and enter a search term',
	search_breadcrumb									: 'Results of search',
	pfi_atoz_bar										: 'Browse by Journal Title:',
	login_to_access										: 'Login to gain access to this result.',
	go_to_detail										: 'Go to detail',
	more_details										: 'More Results',
	view_more_results									: 'View More Results',
	more_loading_msg									: 'Loading. Please wait...',
	previous_title										: 'See previous',
	previous											: 'Previous',
	next_title											: 'See next',
	next												: 'Next',
	update_facets										: 'Update',
	basket_loading										: 'Loading Items. Please wait...',
	basket_item_location								: 'Discovery',
	basket_deselect_hold								: 'Deselect titles from Discovery to Place hold.',
	basket_deselect_list								: 'Deselect titles from Discovery to Add to list.',
	date_valid_format									: 'Please enter a valid year in YYYY format',
	date_invalid										: 'Invalid date. Please enter a date value in YYYY-MM/YYYY-MM format.\n e.g. 1900-01/2000-12.\n Remove all characters and hit enter to remove the date limiter.'						
};
