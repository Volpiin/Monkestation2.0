/obj/structure/destructible/clockwork/eminence_beacon
	name = "Eminence Spire"
	desc = "An ancient, brass spire which holds the spirit of a powerful entity conceived by Rat'var to oversee his faithful servants."
	icon_state = "tinkerers_daemon"
	resistance_flags = INDESTRUCTIBLE
	///are we currently holding a vote for an eminence
	var/vote_active = FALSE
	///ref to our vote timer
	var/vote_timer

/obj/structure/destructible/clockwork/eminence_beacon/attack_hand(mob/user)
	. = ..()
	if(!IS_CLOCK(user))
		return
	if(vote_active)
		var/our_timer = vote_timer //just to be sure we can clear the ref
		vote_timer = null
		deltimer(our_timer)
		vote_active = FALSE
		send_clock_message(null, "[user] has cancelled the Eminence vote.")
		return
	if(GLOB.current_eminence)
		to_chat(user, span_brass("The Eminence has already been released."))
		return

	var/option = tgui_alert(user, "Becoming the Eminence is not an easy task, be sure you will be able to lead the servants. \
								   If you choose to do so, your old form with be destroyed.", "Who shall control the Eminence?", list("Yourself", "A ghost", "Cancel"))
	if(option == "Yourself")
		send_clock_message(null, "[user] has elected themselves to become the Eminence. Interact with \the [src] to object.", "<span class='big_brass'>")
		vote_timer = addtimer(CALLBACK(src, PROC_REF(vote_succeed), user), 60 SECONDS, TIMER_STOPPABLE)
	else if(option == "A ghost")
		send_clock_message(null, "[user] has elected for a ghost to become the Eminence. Interact with \the [src] to object.", "<span class='big_brass'>")
		vote_timer = addtimer(CALLBACK(src, PROC_REF(vote_succeed)), 60 SECONDS, TIMER_STOPPABLE)
	else
		return
	vote_active = TRUE

/obj/structure/destructible/clockwork/eminence_beacon/proc/vote_succeed(mob/eminence)
	vote_active = FALSE
	//this should not happen, but if it does then tell the admins
	if(GLOB.current_eminence)
		message_admins("[type] calling vote_succeed() with a set GLOB.current_eminence, this should not be happening.")

	if(!eminence)
		var/list/mob/dead/observer/candidates = poll_ghost_candidates("Do you want to play as the eminence?", ROLE_CLOCK_CULTIST, poll_time = 10 SECONDS)
		if(LAZYLEN(candidates))
			eminence = pick(candidates)

	if(!(eminence?.client) || !(eminence?.mind))
		send_clock_message(null, "The Eminence remains in slumber, for now, try waking it again soon.")
		return

	var/mob/living/eminence/new_mob = new /mob/living/eminence(get_turf(src))
	var/datum/antagonist/clock_cultist/servant_datum = eminence.mind.has_antag_datum(/datum/antagonist/clock_cultist)
	if(servant_datum)
		servant_datum.silent = TRUE
		servant_datum.on_removal()
	eminence.mind.transfer_to(new_mob, TRUE)
	new_mob.mind.add_antag_datum(/datum/antagonist/clock_cultist/eminence)
	send_clock_message(null, "The Eminence has risen!", "<span class='big_brass'>")

	if(isliving(eminence))
		var/mob/living/living_eminence = eminence
		living_eminence.dust()
