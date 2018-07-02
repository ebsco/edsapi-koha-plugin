/*[% EDSLANG = { 
    home_breadcrumb    									= 'Home'
	eds_results_TT_no_results   						= 'Nessun risultato trovato!'
	eds_results_TT_results_returned_msg					= 'La tua ricerca ha prodotto'
    eds_results_TT_results_msg							= 'risultati.'
    eds_results_TT_did_you_mean							= 'Forse cercavi:'
    eds_results_TT_title_attr							= 'Vedi i dettagli di questo titolo'
    eds_results_TT_links								= 'Link:'
    eds_results_TT_links_html							= 'HTML Full Text'
    eds_results_TT_links_pdf							= 'PDF Full Text'
    eds_results_TT_links_ebook							= 'eBook Full Text'
    eds_results_TT_actions								= 'Azioni:'
    eds_results_TT_place_reserve						= 'Prenota'
    eds_results_TT_save_to_list							= 'Salva nelle liste'
    eds_results_TT_in_cart								= 'Nel carrello'
    eds_results_TT_remove_cart							= '(rimuovi)'
    eds_results_TT_add_cart								= 'Aggiungi al carrello'
	eds_results_TT_login_msg							= 'Fai login per accedere a questo risultato.'
    eds_results_TT_annosuggestions						= 'Non hai trovato quello che stavi cercando?'
    eds_results_TT_annosuggestions_makea				= 'Invia un'
    eds_results_TT_annosuggestions_purchase				= 'suggerimento d\'acquisto'
    
	eds_detail_TT_details_for							= 'Dettagli di:'
	eds_detail_TT_normal_view							= 'Vista normale:'
	eds_detail_TT_login_msg								= 'Fai login per accedere a questo risultato.'
    
    eds_detail_customlinks_INC_html_fulltext			= 'HTML Full Text'
    eds_detail_customlinks_INC_pdf_fulltext				= 'PDF Full Text'
    eds_detail_customlinks_INC_ebook_fulltext			= 'eBook Full Text'
    eds_detail_customlinks_INC_view_in_eds				= 'Vedi in EDS'
    
    eds_detail_sidebar_INC_print						= 'Stampa'
    eds_detail_sidebar_INC_in_cart						= 'Nel carrello'
    eds_detail_sidebar_INC_remove_cart					= '(rimuovi)'
    eds_detail_sidebar_INC_add_cart						= 'Aggiungi al carrello'
        
	eds_advsearch_TT_breadcrumb_home					= 'Home'
    eds_advsearch_TT_breadcrumb_advanced_search			= 'Ricerca avanzata'
    eds_advsearch_TT_select_field						= 'Seleziona un campo (opzionale)'
	eds_advsearch_TT_bool_and							= 'AND'
	eds_advsearch_TT_bool_or							= 'OR'
	eds_advsearch_TT_bool_not							= 'NOT'
    eds_advsearch_TT_opt_add							= 'Aggiungi'
    eds_advsearch_TT_opt_remove							= 'Rimuovi'
    eds_advsearch_TT_search_options						= 'Opzioni'
    eds_advsearch_TT_search_opt_heading					= 'Modalità di ricerca ed espansori'
    eds_advsearch_TT_search_opt_modes					= 'Modalità di ricerca'
    eds_advsearch_TT_search_help_title					= 'Inserisci il testo da ricercare, nella misura che preferisci - una parola, una frase, un paragrafo, anche una pagina intera. Questa modalità cerca solo nelle banche dati EBSCO.'
    eds_advsearch_TT_search_help						= 'Suggerimento'
    eds_advsearch_TT_limit_legend						= 'Limita i risultati'
	eds_advsearch_TT_date_month							= 'Mese'
	eds_advsearch_TT_date_month_jan						= 'Gennaio'
    eds_advsearch_TT_date_month_feb						= 'Febbraio'
    eds_advsearch_TT_date_month_mar						= 'Marzo'
    eds_advsearch_TT_date_month_apr						= 'Aprile'
    eds_advsearch_TT_date_month_may						= 'Maggio'
    eds_advsearch_TT_date_month_jun						= 'Giugno'
    eds_advsearch_TT_date_month_jul						= 'Luglio'
    eds_advsearch_TT_date_month_aug						= 'Agosto'
    eds_advsearch_TT_date_month_sep						= 'Settembre'
    eds_advsearch_TT_date_month_oct						= 'Ottobre'
    eds_advsearch_TT_date_month_nov						= 'Novembre'
    eds_advsearch_TT_date_month_dec						= 'Dicembre'
    eds_advsearch_TT_date_year							= 'Anno:'
    eds_advsearch_TT_btn_search							= 'Cerca'
    eds_advsearch_TT_btn_reset							= 'Reset'
    

    
    eds_facets_INC_refine_search						= 'Raffina la ricerca'
    eds_facets_INC_current_search						= 'Ricerca corrente'
	eds_facets_INC_search_term							= 'Termine(i) di ricerca'
    eds_facets_INC_active_facets						= 'Faccette attive'
    eds_facets_INC_limit_to								= 'Limita a:'
    eds_facets_INC_expand_to							= 'Espandi a:'
    
    eds_page_numbers_INC_previous						= 'Precedente'
    eds_page_numbers_INC_next 							= 'Successivo'
    
    eds_publicationexactmatch_INC_full_text_access		= 'Full Text Access'
    eds_publicationexactmatch_INC_search_within			= 'Cerca nella pubblicazione'
    
    eds_researchstarters_INC_more						= 'Altro.'
    
    eds_resort_form_INC_results_per_page				= 'Risultati per pagina:'
    eds_resort_form_INC_view							= 'Vedi:'
    eds_resort_form_INC_view_title						= 'Titolo'
    eds_resort_form_INC_view_brief						= 'Sintetico'
    eds_resort_form_INC_view_detail						= 'Dettagliato'
    eds_resort_form_INC_search_mode						= 'Modalità di ricerca:'
    eds_resort_form_INC_sort_by							= 'Ordina per:'
}%]*/
var EDSLANG = {
	eds_koha_lang_id									: 'it-IT',
	eds_koha_language									: '[%lang%]',
	eds_switch_text										: 'Passa al Discovery',
	koha_switch_text									: 'Passa al catalogo',
	eds_select_text										: "Discovery",
	koha_select_text                                    : 'Catalogo',
	eds_select_info										: '<h3>Ricerca in EDS</h3>Seleziona una risorsa nota e inserisci un termine di ricerca',
	koha_select_info									: '<h3>Ricerca in Koha</h3>Seleziona una risorsa nota e inserisci un termine di ricerca',
	search_breadcrumb									: 'Risultati di ricerca',
	pfi_atoz_bar										: 'Browse by Journal Title:',
	login_to_access										: 'Fai login per accedere a questo risultato.',
	go_to_detail										: 'Vai al dettaglio',
	more_details										: 'Altri risultati',
	view_more_results									: 'Vedi altri risultati',
	more_loading_msg									: 'Caricamento. Attendi, perfavore...',
	previous_title										: 'Vedi precedente',
	previous											: 'Precedente',
	next_title											: 'Vedi successivo',
	next												: 'Successivo',
	update_facets										: 'Aggiorna',
	basket_loading										: 'Caricamento delle risorse. Attendi, perfavore...',
	basket_item_location								: 'Discovery',
	basket_deselect_hold								: 'Deseleziona titoli dal discoveru per le prenotazioni.',
	basket_deselect_list								: 'Deseleziona titoli dal discovery per aggiunggerli alla lista.',
	date_valid_format									: 'Inserisci un anno nel formato AAAA',
	date_invalid										: 'Data non valida. Inserisci una data nel formato AAAA-MM/AAAA-MM format.\n per es. 1900-01/2000-12.\n Rimuovi tutti i caratteri e premi il tasto Invio per rimuovere il filtro per data.'						
};
