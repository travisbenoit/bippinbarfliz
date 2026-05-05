// Central translation-key registry.
// Keys follow the pattern  <area>.<name>  (all lowercase, dot-separated).
// englishFallback is the source-of-truth for English text; it also acts as the
// ultimate fallback when Supabase has no row for the active language.
class AppStrings {
  AppStrings._();

  // ── Common ──────────────────────────────────────────────────────────────────
  static const ok = 'common.ok';
  static const cancel = 'common.cancel';
  static const save = 'common.save';
  static const close = 'common.close';
  static const done = 'common.done';
  static const next = 'common.next';
  static const skip = 'common.skip';
  static const back = 'common.back';
  static const confirm = 'common.confirm';
  static const error = 'common.error';
  static const loading = 'common.loading';
  static const retry = 'common.retry';
  static const send = 'common.send';
  static const search = 'common.search';
  static const add = 'common.add';
  static const remove = 'common.remove';
  static const share = 'common.share';
  static const block = 'common.block';
  static const unblock = 'common.unblock';
  static const report = 'common.report';
  static const viewAll = 'common.view_all';
  static const unknownUser = 'common.unknown_user';
  static const unknown = 'common.unknown';
  static const optional = 'common.optional';
  static const appName = 'common.app_name';
  static const version = 'common.version';

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const signInTitle = 'auth.sign_in_title';
  static const signInSubtitle = 'auth.sign_in_subtitle';
  static const signInButton = 'auth.sign_in_button';
  static const signInForgot = 'auth.sign_in_forgot';
  static const signInNoAccount = 'auth.sign_in_no_account';
  static const signInGoSignUp = 'auth.sign_in_go_sign_up';
  static const signUpTitle = 'auth.sign_up_title';
  static const signUpSubtitle = 'auth.sign_up_subtitle';
  static const signUpButton = 'auth.sign_up_button';
  static const signUpHaveAccount = 'auth.sign_up_have_account';
  static const signUpGoSignIn = 'auth.sign_up_go_sign_in';
  static const signInEnterEmail = 'auth.sign_in_enter_email';
  static const signInForgotDesc = 'auth.sign_in_forgot_desc';
  static const signInResetEmailSent = 'auth.sign_in_reset_email_sent';
  static const signInSendResetLink = 'auth.sign_in_send_reset_link';
  static const signUpAgreeTerms = 'auth.sign_up_agree_terms';
  static const fieldEmail = 'auth.field_email';
  static const fieldPassword = 'auth.field_password';
  static const fieldName = 'auth.field_name';
  static const fieldConfirmPass = 'auth.field_confirm_password';
  static const signOut = 'auth.sign_out';
  static const signOutTitle = 'auth.sign_out_title';
  static const signOutConfirm = 'auth.sign_out_confirm';

  // ── Navigation (bottom bar + more sheet) ────────────────────────────────────
  static const navHome = 'nav.home';
  static const navMap = 'nav.map';
  static const navMessages = 'nav.messages';
  static const navProfile = 'nav.profile';
  static const navMore = 'nav.more';
  static const moreFriends = 'nav.more_friends';
  static const moreHistory = 'nav.more_history';
  static const morePayments = 'nav.more_payments';
  static const moreLeaderboard = 'nav.more_leaderboard';
  static const moreNightRecap = 'nav.more_night_recap';
  static const moreNotifications = 'nav.more_notifications';

  // ── Onboarding ──────────────────────────────────────────────────────────────
  static const onboardingSkip = 'onboarding.skip';
  static const onboardingNext = 'onboarding.next';
  static const onboardingStart = 'onboarding.get_started';

  // ── Permissions ─────────────────────────────────────────────────────────────
  static const permissionsTitle = 'permissions.title';
  static const permissionsSubtitle = 'permissions.subtitle';
  static const permissionsLocation = 'permissions.location';
  static const permissionsLocSubtitle = 'permissions.location_subtitle';
  static const permissionsNotifs = 'permissions.notifications';
  static const permissionsNotifsSubtitle = 'permissions.notifications_subtitle';
  static const permissionsAllow = 'permissions.allow';
  static const permissionsSkip = 'permissions.skip';
  static const permissionsContinue = 'permissions.continue';

  // ── Home ────────────────────────────────────────────────────────────────────
  static const homeTitle = 'home.title';
  static const homeGoodEvening = 'home.good_evening';
  static const homeTonightStatus = 'home.tonight_status';
  static const homeGoingOut = 'home.going_out';
  static const homeMaybe = 'home.maybe';
  static const homeStayingIn = 'home.staying_in';
  static const homeOutNow = 'home.out_now';
  static const homePopularVenues = 'home.popular_venues';
  static const homeActiveSwarms = 'home.active_swarms';
  static const homeQuickActions = 'home.quick_actions';
  static const homeNearbyPeople = 'home.nearby_people';
  static const homeSceneTonight = 'home.scene_tonight';
  static const homeDdTonight = 'home.dd_tonight';
  static const homeSafeArrival = 'home.safe_arrival';
  static const homeCheckins = 'home.checkins';
  static const homeFriends = 'home.friends';
  static const homeSwarms = 'home.swarms';
  static const homeLevel = 'home.level';
  static const homeXp = 'home.xp';
  static const homeStreak = 'home.streak';
  static const homeNoVenues = 'home.no_venues';
  static const homeNoSwarms = 'home.no_swarms';
  static const homeNoNearby = 'home.no_nearby';
  static const homePeopleOut = 'home.people_out';
  static const homeCheckIn = 'home.check_in';
  static const homeSendGift = 'home.send_gift';
  static const homeMapView = 'home.map_view';
  static const homeCreateSwarm = 'home.create_swarm';

  // ── Map ─────────────────────────────────────────────────────────────────────
  static const mapTitle = 'map.title';
  static const mapVenues = 'map.venues';
  static const mapPeople = 'map.people';
  static const mapFilterAll = 'map.filter_all';
  static const mapFilterBars = 'map.filter_bars';
  static const mapFilterClubs = 'map.filter_clubs';
  static const mapFilterRestaurants = 'map.filter_restaurants';
  static const mapNoVenues = 'map.no_venues';
  static const mapOpenInMaps = 'map.open_in_maps';
  static const mapGetDirections = 'map.get_directions';
  static const mapCheckIn = 'map.check_in';

  // ── Messages ────────────────────────────────────────────────────────────────
  static const messagesTitle = 'messages.title';
  static const messagesEmpty = 'messages.empty';
  static const messagesEmptySub = 'messages.empty_subtitle';
  static const messagesHint = 'messages.hint';
  static const messagesYou = 'messages.you';
  static const chatTitle = 'messages.chat_title';
  static const chatInputHint = 'messages.chat_input_hint';
  static const chatSend = 'messages.chat_send';

  // ── Profile ─────────────────────────────────────────────────────────────────
  static const profileTitle = 'profile.title';
  static const profileEdit = 'profile.edit';
  static const profileFollowers = 'profile.followers';
  static const profileFollowing = 'profile.following';
  static const profileFriends = 'profile.friends';
  static const profileBio = 'profile.bio';
  static const profileInterests = 'profile.interests';
  static const profileCheckins = 'profile.checkins';
  static const profileXp = 'profile.xp';
  static const profileLevel = 'profile.level';
  static const profileAddFriend = 'profile.add_friend';
  static const profileSendGift = 'profile.send_gift';
  static const profileSendMessage = 'profile.send_message';
  static const profileBlockUser = 'profile.block_user';
  static const profileReportUser = 'profile.report_user';

  // ── Friends ─────────────────────────────────────────────────────────────────
  static const friendsTitle = 'friends.title';
  static const friendsTabFriends = 'friends.tab_friends';
  static const friendsTabRequests = 'friends.tab_requests';
  static const friendsTabFind = 'friends.tab_find';
  static const friendsEmpty = 'friends.empty';
  static const friendsEmptySub = 'friends.empty_subtitle';
  static const friendsNoRequests = 'friends.no_requests';
  static const friendsNoRequestsSub = 'friends.no_requests_subtitle';
  static const friendsSearchHint = 'friends.search_hint';
  static const friendsAccept = 'friends.accept';
  static const friendsDecline = 'friends.decline';
  static const friendsPending = 'friends.pending';
  static const friendsRemove = 'friends.remove_friend';
  static const friendsAddFriend = 'friends.add_friend';
  static const friendsRequestSent = 'friends.request_sent';
  static const friendsAlready = 'friends.already_friends';
  static const friendsMutualCount = 'friends.mutual_count';
  static const friendsFindPeople = 'friends.find_people';

  // ── Notifications ───────────────────────────────────────────────────────────
  static const notificationsTitle = 'notifications.title';
  static const notificationsEmpty = 'notifications.empty';
  static const notificationsMarkAll = 'notifications.mark_all_read';
  static const notificationsToday = 'notifications.today';
  static const notificationsEarlier = 'notifications.earlier';

  // ── Leaderboard ─────────────────────────────────────────────────────────────
  static const leaderboardTitle = 'leaderboard.title';
  static const leaderboardTab = 'leaderboard.tab_leaderboard';
  static const challengesTab = 'leaderboard.tab_challenges';
  static const leaderboardMyStats = 'leaderboard.my_stats';
  static const leaderboardRank = 'leaderboard.rank';
  static const leaderboardXp = 'leaderboard.xp';
  static const leaderboardStreak = 'leaderboard.streak';
  static const leaderboardCheckins = 'leaderboard.checkins';
  static const leaderboardEmpty = 'leaderboard.empty';
  static const challengesEmpty = 'leaderboard.challenges_empty';
  static const challengeCompleted = 'leaderboard.challenge_completed';
  static const challengeInProgress = 'leaderboard.challenge_in_progress';
  static const challengeLocked = 'leaderboard.challenge_locked';
  static const challengeXpReward = 'leaderboard.challenge_xp_reward';

  // ── Settings ────────────────────────────────────────────────────────────────
  static const settingsTitle = 'settings.title';
  static const settingsAccount = 'settings.section_account';
  static const settingsSocial = 'settings.section_social';
  static const settingsPrivacy = 'settings.section_privacy';
  static const settingsPayments = 'settings.section_payments';
  static const settingsMore = 'settings.section_more';
  static const settingsEditProfile = 'settings.edit_profile';
  static const settingsEditProfileSub = 'settings.edit_profile_subtitle';
  static const settingsAppearance = 'settings.appearance';
  static const settingsDarkOn = 'settings.dark_mode_on';
  static const settingsLightOn = 'settings.light_mode_on';
  static const settingsLanguage = 'settings.language';
  static const settingsLanguageSub = 'settings.language_subtitle';
  static const settingsFriends = 'settings.friends';
  static const settingsFriendsSub = 'settings.friends_subtitle';
  static const settingsNotifications = 'settings.notifications';
  static const settingsNotifsSub = 'settings.notifications_subtitle';
  static const settingsSafety = 'settings.safety';
  static const settingsSafetySub = 'settings.safety_subtitle';
  static const settingsBlocked = 'settings.blocked_users';
  static const settingsBlockedSub = 'settings.blocked_users_subtitle';
  static const settingsPremium = 'settings.premium';
  static const settingsPremiumSub = 'settings.premium_subtitle';
  static const settingsPaymentsTitle = 'settings.payments';
  static const settingsPaymentsSub = 'settings.payments_subtitle';
  static const settingsMyGifts = 'settings.my_gifts';
  static const settingsMyGiftsSub = 'settings.my_gifts_subtitle';
  static const settingsHistory = 'settings.history';
  static const settingsHistorySub = 'settings.history_subtitle';
  static const settingsLeaderboard = 'settings.leaderboard';
  static const settingsLeaderboardSub = 'settings.leaderboard_subtitle';
  static const settingsHelp = 'settings.help';
  static const settingsHelpSub = 'settings.help_subtitle';
  static const settingsPrivacyPolicy = 'settings.privacy_policy';
  static const settingsPrivacySub = 'settings.privacy_policy_subtitle';
  static const settingsTerms = 'settings.terms';

  // ── Language settings ───────────────────────────────────────────────────────
  static const languageTitle = 'language.title';
  static const languageSelect = 'language.select';

  // ── Blocked users ───────────────────────────────────────────────────────────
  static const blockedTitle = 'blocked.title';
  static const blockedEmpty = 'blocked.empty';
  static const blockedEmptySub = 'blocked.empty_subtitle';
  static const blockedOn = 'blocked.blocked_on';
  static const blockedUnblock = 'blocked.unblock';
  static const blockedLoadError = 'blocked.load_error';
  static const blockedUnblockOk = 'blocked.unblock_success';
  static const blockedUnblockError = 'blocked.unblock_error';

  // ── Send Gift ───────────────────────────────────────────────────────────────
  static const giftTitle = 'gift.title';
  static const giftTitleTo = 'gift.title_to';
  static const giftChooseDrink = 'gift.choose_drink';
  static const giftAmount = 'gift.amount';
  static const giftMessageHint = 'gift.message_hint';
  static const giftSendButton = 'gift.send_button';
  static const giftSentSuccess = 'gift.sent_success';
  static const giftSendError = 'gift.send_error';
  static const giftDrinkBeer = 'gift.drink_beer';
  static const giftDrinkWine = 'gift.drink_wine';
  static const giftDrinkCocktail = 'gift.drink_cocktail';
  static const giftDrinkShot = 'gift.drink_shot';
  static const giftDrinkCustom = 'gift.drink_custom';

  // ── Gifts received ──────────────────────────────────────────────────────────
  static const giftsTitle = 'gifts.title';
  static const giftsEmpty = 'gifts.empty';
  static const giftsEmptySub = 'gifts.empty_subtitle';
  static const giftsFrom = 'gifts.from';
  static const giftsPending = 'gifts.pending';
  static const giftsAccepted = 'gifts.accepted';

  // ── History ─────────────────────────────────────────────────────────────────
  static const historyTitle = 'history.title';
  static const historyTabActivity = 'history.tab_activity';
  static const historyTabVisits = 'history.tab_visits';
  static const historyEmpty = 'history.empty';
  static const historyEmptySub = 'history.empty_subtitle';

  // ── Payments ────────────────────────────────────────────────────────────────
  static const paymentsTitle = 'payments.title';
  static const paymentsTabOverview = 'payments.tab_overview';
  static const paymentsTabSend = 'payments.tab_send';
  static const paymentsTabHistory = 'payments.tab_history';
  static const paymentsBalance = 'payments.balance';
  static const paymentsLushCoins = 'payments.lush_coins';
  static const paymentsSendMoney = 'payments.send_money';
  static const paymentsEmpty = 'payments.empty';

  // ── Premium ─────────────────────────────────────────────────────────────────
  static const premiumTitle = 'premium.title';
  static const premiumSubtitle = 'premium.subtitle';
  static const premiumMonthly = 'premium.monthly';
  static const premiumYearly = 'premium.yearly';
  static const premiumGetPremium = 'premium.get_premium';
  static const premiumAlreadySub = 'premium.already_subscribed';
  static const premiumFeaturesTitle = 'premium.features_title';

  // ── Discover ────────────────────────────────────────────────────────────────
  static const discoverTitle = 'discover.title';
  static const discoverNoResults = 'discover.no_results';
  static const discoverLike = 'discover.like';
  static const discoverSkip = 'discover.skip';
  static const discoverMatch = 'discover.match';

  // ── People Nearby ───────────────────────────────────────────────────────────
  static const peopleTitle = 'people.title';
  static const peopleEmpty = 'people.empty';
  static const peopleEmptySub = 'people.empty_subtitle';
  static const peopleFilterAll = 'people.filter_all';
  static const peopleFilterOut = 'people.filter_out_now';
  static const peopleFilterGoing = 'people.filter_going_out';
  static const peopleSearchHint = 'people.search_hint';
  static const peopleNearby = 'people.nearby_count';
  static const peopleAddFriend = 'people.add_friend';

  // ── Swarms ──────────────────────────────────────────────────────────────────
  static const swarmsTitle = 'swarms.title';
  static const swarmsCreate = 'swarms.create';
  static const swarmsJoin = 'swarms.join';
  static const swarmsEmpty = 'swarms.empty';
  static const swarmsEmptySub = 'swarms.empty_subtitle';
  static const swarmsMembers = 'swarms.members';
  static const swarmsLeave = 'swarms.leave';

  // ── Safety ──────────────────────────────────────────────────────────────────
  static const safetyTitle = 'safety.title';
  static const safetyGhostMode = 'safety.ghost_mode';
  static const safetyGhostSub = 'safety.ghost_mode_subtitle';
  static const safetySafeArrival = 'safety.safe_arrival';
  static const safetySafeArrivalSub = 'safety.safe_arrival_subtitle';
  static const safetyEmergency = 'safety.emergency_contacts';
  static const safetyEmergencySub = 'safety.emergency_contacts_subtitle';
  static const safetyBlockedUsers = 'safety.blocked_users';

  // ── Notifications settings ──────────────────────────────────────────────────
  static const notifSettingsTitle = 'notif_settings.title';
  static const notifSettingsSaved = 'notif_settings.saved';

  // ── Edit profile ────────────────────────────────────────────────────────────
  static const editProfileTitle = 'edit_profile.title';
  static const editProfileSave = 'edit_profile.save';
  static const editProfileName = 'edit_profile.name';
  static const editProfileBio = 'edit_profile.bio';
  static const editProfileDob = 'edit_profile.dob';
  static const editProfileInterests = 'edit_profile.interests';
  static const editProfilePhoto = 'edit_profile.change_photo';

  // ── Night Recap ─────────────────────────────────────────────────────────────
  static const recapTitle = 'recap.title';
  static const recapSubtitle = 'recap.subtitle';
  static const recapVenues = 'recap.venues_visited';
  static const recapPeople = 'recap.people_met';
  static const recapXpEarned = 'recap.xp_earned';

  // ── The Room ────────────────────────────────────────────────────────────────
  static const roomTitle = 'room.title';
  static const roomTabChat = 'room.tab_chat';
  static const roomTabPeople = 'room.tab_people';
  static const roomTabPhotos = 'room.tab_photos';
  static const roomTabMoments = 'room.tab_moments';
  static const roomInputHint = 'room.input_hint';

  // ── Music ───────────────────────────────────────────────────────────────────
  static const musicTitle = 'music.title';
  static const musicSearchHint = 'music.search_hint';
  static const musicLike = 'music.like';
  static const musicBy = 'music.by';
  static const musicShare = 'music.share';
  static const musicShared = 'music.shared';
  static const musicEmpty = 'music.empty';

  // ── Profile setup ───────────────────────────────────────────────────────────
  static const profileSetupTitle = 'profile_setup.title';
  static const profileSetupSubtitle = 'profile_setup.subtitle';
  static const profileSetupContinue = 'profile_setup.continue';

  // ── Safe Arrival ────────────────────────────────────────────────────────────
  static const safeArrivalTitle = 'safe_arrival.title';
  static const safeArrivalChecked = 'safe_arrival.checked_in';
  static const safeArrivalNotify = 'safe_arrival.notify_contacts';

  // ── Report ──────────────────────────────────────────────────────────────────
  static const reportTitle = 'report.title';
  static const reportSubmit = 'report.submit';
  static const reportSuccess = 'report.success';
  static const reportReasonSpam = 'report.reason_spam';
  static const reportReasonHarassment = 'report.reason_harassment';
  static const reportReasonHate = 'report.reason_hate_speech';
  static const reportReasonSexual = 'report.reason_sexual_content';
  static const reportReasonViolence = 'report.reason_violence';
  static const reportReasonUnderage = 'report.reason_underage';
  static const reportReasonImpersonation = 'report.reason_impersonation';
  static const reportReasonSafety = 'report.reason_safety';
  static const reportReasonOther = 'report.reason_other';

  // ── First run tour ──────────────────────────────────────────────────────────
  static const tourStep1Title = 'tour.step1_title';
  static const tourStep1Body = 'tour.step1_body';
  static const tourStep2Title = 'tour.step2_title';
  static const tourStep2Body = 'tour.step2_body';
  static const tourStep3Title = 'tour.step3_title';
  static const tourStep3Body = 'tour.step3_body';
  static const tourStep4Title = 'tour.step4_title';
  static const tourStep4Body = 'tour.step4_body';
  static const tourLetsGo = 'tour.lets_go';

  // ── Dialogs ─────────────────────────────────────────────────────────────────
  static const helpTitle = 'help.title';
  static const helpFaq = 'help.faq';
  static const helpQ1 = 'help.q1';
  static const helpQ2 = 'help.q2';
  static const helpQ3 = 'help.q3';
  static const helpQ4 = 'help.q4';
  static const privacyTitle = 'privacy.title';
  static const termsTitle = 'terms.title';

  // ── Home (extra) ─────────────────────────────────────────────────────────────
  static const homeGoingOut2 = 'home.going_out_soon'; // "Going Out Soon"
  static const homeAppTagline = 'home.app_tagline';
  static const homeEditStatus = 'home.edit_status';
  static const homeVibes = 'home.vibes';
  static const homeDrinks = 'home.drinks';
  static const homeLushCoins = 'home.lush_coins';
  static const homeYourStats = 'home.your_stats';
  static const homeNoOneTonightScene = 'home.no_one_tonight_scene';
  static const homeNoVenuesFound = 'home.no_venues_found';
  static const homeNoActiveSwarmsLong = 'home.no_active_swarms_long';
  static const homeDdToggleTitle = 'home.dd_toggle_title';
  static const homeDdToggleSub = 'home.dd_toggle_sub';
  static const homeCheckInSafeArrival = 'home.check_in_safe_arrival';
  static const homeUpdateStatus = 'home.update_status';
  static const homeSaveStatus = 'home.save_status';
  static const homeSafeArrivalRecorded = 'home.safe_arrival_recorded';
  static const homeCouldNotLoadProfile = 'home.could_not_load_profile';
  static const homeProfileNotFound = 'home.profile_not_found';
  static const homeCouldNotLoadPeople = 'home.could_not_load_people';
  static const homeCouldNotLoadVenues = 'home.could_not_load_venues';
  static const homeCouldNotLoadSwarms = 'home.could_not_load_swarms';
  static const homeSeeAll = 'home.see_all';
  static const homeQuickCreateSwarm = 'home.quick_create_swarm';
  static const homeQuickSendMessage = 'home.quick_send_message';
  static const homeQuickFindVenues = 'home.quick_find_venues';
  static const homeQuickFindPeople = 'home.quick_find_people';
  static const homeQuickViewHistory = 'home.quick_view_history';
  static const homeQuickFriends = 'home.quick_friends';
  static const homeStatNearby = 'home.stat_nearby';
  static const homeStatOutNow = 'home.stat_out_now';
  static const homeStatVenues = 'home.stat_venues';
  static const homeMaxAttendees = 'home.max_attendees';

  // ── Auth (extra) ─────────────────────────────────────────────────────────────
  static const authValidEmailRequired = 'auth.valid_email_required';
  static const authValidEmailFormat = 'auth.valid_email_format';
  static const authPasswordRequired = 'auth.password_required';
  static const authPasswordMinLength = 'auth.password_min_length';
  static const authConfirmPasswordRequired = 'auth.confirm_password_required';
  static const authPasswordsNoMatch = 'auth.passwords_no_match';
  static const authAgreeToTerms = 'auth.agree_to_terms';
  static const authIAgree = 'auth.i_agree';
  static const authAnd = 'auth.and';
  static const authSignUpFailed = 'auth.sign_up_failed';
  static const authSignInFailed = 'auth.sign_in_failed';
  static const authForgotPasswordHint = 'auth.forgot_password_hint';
  static const authPasswordResetSent = 'auth.password_reset_sent';
  static const authSendResetLink = 'auth.send_reset_link';

  // ── Messages (extra) ─────────────────────────────────────────────────────────
  static const messagesNoMsgYet = 'messages.no_msg_yet';
  static const messagesStartConvo = 'messages.start_convo';
  static const chatNoMsgYet = 'messages.chat_no_msg_yet';
  static const chatSayHello = 'messages.chat_say_hello';
  static const chatFailedSend = 'messages.chat_failed_send';
  static const chatTypeMsg = 'messages.chat_type_msg';
  static const chatNotLoggedIn = 'messages.chat_not_logged_in';

  // ── Notifications (extra) ────────────────────────────────────────────────────
  static const notificationsUnread = 'notifications.unread';
  static const notificationsMarkAllRead = 'notifications.mark_all_read_btn';
  static const notificationsAllCaughtUp = 'notifications.all_caught_up';
  static const notificationsError = 'notifications.error';

  // ── Profile (extra) ──────────────────────────────────────────────────────────
  static const profileErrorLoading = 'profile.error_loading';
  static const profileNotFound = 'profile.not_found';
  static const profileYearsOld = 'profile.years_old';
  static const profileTonightStatus = 'profile.tonight_status';
  static const profileChange = 'profile.change';
  static const profileAboutMe = 'profile.about_me';
  static const profileNoBio = 'profile.no_bio';
  static const profileVibeTags = 'profile.vibe_tags';
  static const profileFavoritesDrinks = 'profile.favorite_drinks';
  static const profilePremium = 'profile.premium';
  static const profileYes = 'profile.yes';
  static const profileNo = 'profile.no';

  // ── Map (extra) ──────────────────────────────────────────────────────────────
  static const mapLoadingVenues = 'map.loading_venues';
  static const mapVenuesNearby = 'map.venues_nearby';
  static const mapTapMarker = 'map.tap_marker';
  static const mapDirections = 'map.directions';
  static const mapCheckInVenue = 'map.check_in_venue';

  // ── Discover (extra) ─────────────────────────────────────────────────────────
  static const discoverNoOne = 'discover.no_one';
  static const discoverCheckBack = 'discover.check_back';
  static const discoverRefresh = 'discover.refresh';
  static const discoverYouLiked = 'discover.you_liked';
  static const discoverError = 'discover.error';

  // ── People (extra) ───────────────────────────────────────────────────────────
  static const peopleFilterDd = 'people.filter_dd';
  static const peoplePerson = 'people.person';
  static const peoplePeople = 'people.people';
  static const peopleOutTonight = 'people.out_tonight';
  static const peopleChat = 'people.chat';
  static const peopleFriends = 'people.friends';
  static const peoplePending = 'people.pending';
  static const peopleAddFriendBtn = 'people.add_friend_btn';
  static const peopleSomethingWrong = 'people.something_wrong';
  static const peopleNoOneNearby = 'people.no_one_nearby';
  static const peopleNoFilter = 'people.no_filter';
  static const peoplePullRefresh = 'people.pull_refresh';
  static const peopleSearchHintName = 'people.search_hint_name';

  // ── Swarms (extra) ───────────────────────────────────────────────────────────
  static const swarmsComingSoon = 'swarms.coming_soon';
  static const swarmsCreateNew = 'swarms.create_new';
  static const swarmsStartsInMinutes = 'swarms.starts_in_minutes';
  static const swarmsStartsInHours = 'swarms.starts_in_hours';
  static const swarmsMax = 'swarms.max';
  static const swarmsNameLabel = 'swarms.name_label';
  static const swarmsNameHint = 'swarms.name_hint';
  static const swarmsNameRequired = 'swarms.name_required';
  static const swarmsDescLabel = 'swarms.desc_label';
  static const swarmsDescHint = 'swarms.desc_hint';
  static const swarmsStartTimeLabel = 'swarms.start_time_label';
  static const swarmsPickTime = 'swarms.pick_time';
  static const swarmsMaxAttendeesLabel = 'swarms.max_attendees_label';
  static const swarmsVibeTagsLabel = 'swarms.vibe_tags_label';
  static const swarmsCreateSuccess = 'swarms.create_success';
  static const swarmsCreateFailed = 'swarms.create_failed';
  static const swarmsPublish = 'swarms.publish';

  // ── History (extra) ──────────────────────────────────────────────────────────
  static const historyVisitsEmpty = 'history.visits_empty';
  static const historyVisitsEmptySub = 'history.visits_empty_subtitle';
  static const historyTypeCheckin = 'history.type_checkin';
  static const historyTypeMessage = 'history.type_message';
  static const historyTypeSwarm = 'history.type_swarm';
  static const historyTypeFriend = 'history.type_friend';
  static const historyTypeGift = 'history.type_gift';

  // ── Payments (extra) ─────────────────────────────────────────────────────────
  static const paymentsAddCoins = 'payments.add_coins';
  static const paymentsLinkMethod = 'payments.link_method';
  static const paymentsRequestPayment = 'payments.request_payment';
  static const paymentsInvalidAmount = 'payments.invalid_amount';
  static const paymentsNoteLabel = 'payments.note_label';
  static const paymentsNoteHint = 'payments.note_hint';
  static const paymentsHistoryEmptySub = 'payments.history_empty_sub';
  static const paymentsSearchHint = 'payments.search_hint';
  static const paymentsAmountUsd = 'payments.amount_usd';
  static const paymentsLinked = 'payments.linked';
  static const paymentsSendingTo = 'payments.sending_to';
  static const paymentsCoinsAvailable = 'payments.coins_available';
  static const paymentsPaymentMethod = 'payments.payment_method';
  static const paymentsNoMethodLinked = 'payments.no_method_linked';
  static const paymentsLinkCard = 'payments.link_card';
  static const paymentsTotalSent = 'payments.total_sent';
  static const paymentsTotalReceived = 'payments.total_received';
  static const paymentsTransactions = 'payments.transactions';
  static const paymentsNoTransactions = 'payments.no_transactions';
  static const paymentsSent = 'payments.sent';
  static const paymentsReceived = 'payments.received';
  static const paymentsSendTo = 'payments.send_to';
  static const paymentsAmount = 'payments.amount';
  static const paymentsSendPayment = 'payments.send_payment';
  static const paymentsPaymentSent = 'payments.payment_sent';
  static const paymentsPaymentReceived = 'payments.payment_received';
  static const paymentsComingSoon = 'payments.coming_soon';
  static const paymentsStripeNote = 'payments.stripe_note';
  static const paymentsVenmoComingSoon = 'payments.venmo_coming_soon';
  static const paymentsPaypalComingSoon = 'payments.paypal_coming_soon';
  static const paymentsCashappComingSoon = 'payments.cashapp_coming_soon';
  static const paymentsPaymentSentTo = 'payments.payment_sent_to';
  static const paymentsFailedSend = 'payments.failed_send';

  // ── Gifts (extra) ────────────────────────────────────────────────────────────
  static const giftsMyGifts = 'gifts.my_gifts';
  static const giftsNoGiftsYet = 'gifts.no_gifts_yet';
  static const giftsNoGiftsSub = 'gifts.no_gifts_sub';

  // ── Leaderboard (extra) ──────────────────────────────────────────────────────
  static const leaderboardSignInStats = 'leaderboard.sign_in_stats';
  static const leaderboardYourStats = 'leaderboard.your_stats';
  static const leaderboardNightStreak = 'leaderboard.night_streak';
  static const leaderboardNoChallenges = 'leaderboard.no_challenges';
  static const leaderboardCompleteXp = 'leaderboard.complete_xp';
  static const leaderboardXpEarned = 'leaderboard.xp_earned';
  static const leaderboardFromChallenges = 'leaderboard.from_challenges';
  static const leaderboardError = 'leaderboard.error';
  static const leaderboardCheckIns = 'leaderboard.check_ins';

  // ── Friends (extra) ──────────────────────────────────────────────────────────
  static const friendsMessage = 'friends.message';
  static const friendsAcceptBtn = 'friends.accept_btn';
  static const friendsDeclineBtn = 'friends.decline_btn';
  static const friendsAddFriendBtn = 'friends.add_friend_btn';
  static const friendsFriendsLabel = 'friends.friends_label';
  static const friendsPendingLabel = 'friends.pending_label';
  static const friendsNoFriendsTitle = 'friends.no_friends_title';
  static const friendsNoFriendsSub = 'friends.no_friends_sub';
  static const friendsNoPendingTitle = 'friends.no_pending_title';
  static const friendsNoPendingSub = 'friends.no_pending_sub';
  static const friendsNoOneFound = 'friends.no_one_found';
  static const friendsNoOneFoundSub = 'friends.no_one_found_sub';
  static const friendsSomethingWrong = 'friends.something_wrong';
  static const friendsSearchHintName = 'friends.search_hint_name';

  // ── Premium (extra) ──────────────────────────────────────────────────────────
  static const premiumComingSoon = 'premium.coming_soon';
  static const premiumComingSoonMsg = 'premium.coming_soon_msg';
  static const premiumNotifyMe = 'premium.notify_me';
  static const premiumNotifyConfirm = 'premium.notify_confirm';
  static const premiumFeatureUnlimitedSwipes =
      'premium.feature_unlimited_swipes';
  static const premiumFeatureUnlimitedSwipesSub =
      'premium.feature_unlimited_swipes_sub';
  static const premiumFeatureSeeWhoLikes = 'premium.feature_see_who_likes';
  static const premiumFeatureSeeWhoLikesSub =
      'premium.feature_see_who_likes_sub';
  static const premiumFeatureAdvancedFilters =
      'premium.feature_advanced_filters';
  static const premiumFeatureAdvancedFiltersSub =
      'premium.feature_advanced_filters_sub';
  static const premiumFeatureNoAds = 'premium.feature_no_ads';
  static const premiumFeatureNoAdsSub = 'premium.feature_no_ads_sub';

  // ── Sign-in (extra) ──────────────────────────────────────────────────────────
  static const signInValidEmail = 'auth.sign_in_valid_email';
  static const signInValidEmailFormat = 'auth.sign_in_valid_email_format';
  static const signInPasswordRequired = 'auth.sign_in_password_required';

  // ── Onboarding (extra) ───────────────────────────────────────────────────────
  static const onboardingSlide1Title = 'onboarding.slide1_title';
  static const onboardingSlide1Sub = 'onboarding.slide1_sub';
  static const onboardingSlide2Title = 'onboarding.slide2_title';
  static const onboardingSlide2Sub = 'onboarding.slide2_sub';
  static const onboardingSlide3Title = 'onboarding.slide3_title';
  static const onboardingSlide3Sub = 'onboarding.slide3_sub';
  static const onboardingGetStarted = 'onboarding.get_started_btn';
  static const onboardingAlreadyAccount = 'onboarding.already_account';
  static const onboardingSignIn = 'onboarding.sign_in';

  // ── Profile Setup (extra) ────────────────────────────────────────────────────
  static const profileSetupNameLabel = 'profile_setup.name_label';
  static const profileSetupNameHint = 'profile_setup.name_hint';
  static const profileSetupNameRequired = 'profile_setup.name_required';
  static const profileSetupBioLabel = 'profile_setup.bio_label';
  static const profileSetupBioHint = 'profile_setup.bio_hint';
  static const profileSetupSaved = 'profile_setup.saved';
  static const profileSetupError = 'profile_setup.error';

  // ── Safe Arrival (extra) ─────────────────────────────────────────────────────
  static const safeArrivalStaySafe = 'safe_arrival.stay_safe';
  static const safeArrivalSafeRecorded = 'safe_arrival.safe_recorded';
  static const safeArrivalNotifyContacts = 'safe_arrival.notify_contacts_btn';
  static const safeArrivalAddContact = 'safe_arrival.add_contact';
  static const safeArrivalEmergency = 'safe_arrival.emergency';
  static const safeArrivalEmergencyContacts = 'safe_arrival.emergency_contacts';
  static const safeArrivalNoContacts = 'safe_arrival.no_contacts';
  static const safeArrivalCheckinNow = 'safe_arrival.checkin_now';

  // ── Edit Profile (extra) ─────────────────────────────────────────────────────
  static const editProfileSaved = 'edit_profile.saved';
  static const editProfileError = 'edit_profile.error';
  static const editProfileNameLabel = 'edit_profile.name_label';
  static const editProfileBioLabel = 'edit_profile.bio_label';
  static const editProfileDobLabel = 'edit_profile.dob_label';
  static const editProfileStatusLabel = 'edit_profile.status_label';
  static const editProfileVibeTags = 'edit_profile.vibe_tags';
  static const editProfileFavDrinks = 'edit_profile.fav_drinks';
  static const editProfileStatusOutNow = 'edit_profile.status_out_now';
  static const editProfileStatusGoing = 'edit_profile.status_going';
  static const editProfileStatusStaying = 'edit_profile.status_staying';

  // ── Safety Settings (extra) ──────────────────────────────────────────────────
  static const safetyPrivacy = 'safety.privacy';
  static const safetyGhostModeTitle = 'safety.ghost_mode_title';
  static const safetyProfileVisibility = 'safety.profile_visibility';
  static const safetyVisibilityEveryone = 'safety.visibility_everyone';
  static const safetyVisibilityFriends = 'safety.visibility_friends';
  static const safetyVisibilityNone = 'safety.visibility_none';
  static const safetyBlockedUsersTitle = 'safety.blocked_users_title';
  static const safetyNoBlocked = 'safety.no_blocked';
  static const safetyAccount = 'safety.account';
  static const safetyDeleteAccount = 'safety.delete_account';
  static const safetyDeleteAccountSub = 'safety.delete_account_sub';
  static const safetyYourData = 'safety.your_data';
  static const safetyDownloadData = 'safety.download_data';
  static const safetyDownloadDataSub = 'safety.download_data_sub';
  static const safetyDeleteConfirmTitle = 'safety.delete_confirm_title';
  static const safetyDeleteConfirmMsg = 'safety.delete_confirm_msg';
  static const safetyDeleteConfirmBtn = 'safety.delete_confirm_btn';
  static const safetyDownloadComingSoon = 'safety.download_coming_soon';

  // ── Notif Settings (extra) ───────────────────────────────────────────────────
  static const notifSettingsSocial = 'notif_settings.social';
  static const notifSettingsLocation = 'notif_settings.location';
  static const notifSettingsOther = 'notif_settings.other';
  static const notifSettingsSaveError = 'notif_settings.save_error';
  static const notifFriendReq = 'notif_settings.friend_request';
  static const notifFriendReqSub = 'notif_settings.friend_request_sub';
  static const notifFriendAccepted = 'notif_settings.friend_accepted';
  static const notifFriendAcceptedSub = 'notif_settings.friend_accepted_sub';
  static const notifMessages = 'notif_settings.messages';
  static const notifMessagesSub = 'notif_settings.messages_sub';
  static const notifGifts = 'notif_settings.gifts';
  static const notifGiftsSub = 'notif_settings.gifts_sub';
  static const notifNearbyFriends = 'notif_settings.nearby_friends';
  static const notifNearbyFriendsSub = 'notif_settings.nearby_friends_sub';
  static const notifCheckins = 'notif_settings.checkins';
  static const notifCheckinsSub = 'notif_settings.checkins_sub';
  static const notifSwarms = 'notif_settings.swarms';
  static const notifSwarmsSub = 'notif_settings.swarms_sub';
  static const notifPromo = 'notif_settings.promo';
  static const notifPromoSub = 'notif_settings.promo_sub';
  static const notifWeekly = 'notif_settings.weekly';
  static const notifWeeklySub = 'notif_settings.weekly_sub';

  // ── Night Recap (extra) ──────────────────────────────────────────────────────
  static const recapTimeline = 'recap.timeline';
  static const recapShareBtn = 'recap.share_btn';
  static const recapNothingYet = 'recap.nothing_yet';
  static const recapFindVenues = 'recap.find_venues';
  static const recapNightRoute = 'recap.night_route';
  static const recapCheckins = 'recap.checkins';
  static const recapGiftsSent = 'recap.gifts_sent';
  static const recapXp = 'recap.xp';

  // ── Music (extra) ────────────────────────────────────────────────────────────
  static const musicSearchTitle = 'music.search_title';
  static const musicSearchHintFull = 'music.search_hint_full';
  static const musicStartTyping = 'music.start_typing';
  static const musicNoResults = 'music.no_results';
  static const musicError = 'music.error';
  static const musicShareTitle = 'music.share_title';
  static const musicShareHint = 'music.share_hint';
  static const musicSharedOk = 'music.shared_ok';
  static const musicShareFailed = 'music.share_failed';
  static const musicSearchFailed = 'music.search_failed';
  static const musicTabDiscover = 'music.tab_discover';
  static const musicTabMyShares = 'music.tab_my_shares';
  static const musicNoMyShares = 'music.no_my_shares';

  // ── Room (extra) ─────────────────────────────────────────────────────────────
  static const roomSendPhoto = 'room.send_photo';
  static const roomPresenceTitle = 'room.presence_title';
  static const roomPhotoWall = 'room.photo_wall';
  static const roomVibeTitle = 'room.vibe_title';
  static const roomNoMessages = 'room.no_messages';
  static const roomNoPhotos = 'room.no_photos';
  static const roomNoMoments = 'room.no_moments';

  // ── Permissions (extra) ──────────────────────────────────────────────────────
  static const permissionsLocationDenied = 'permissions.location_denied';
  static const permissionsLocationDeniedSub = 'permissions.location_denied_sub';
  static const permissionsOpenSettings = 'permissions.open_settings';
  static const permissionsCameraTitle = 'permissions.camera_title';
  static const permissionsCameraSubtitle = 'permissions.camera_subtitle';
  static const permissionsCameraAllow = 'permissions.camera_allow';
  static const permissionsNotifsScreenTitle = 'permissions.notifs_screen_title';
  static const permissionsNotifsScreenSubtitle =
      'permissions.notifs_screen_subtitle';
  static const permissionsLocationTitle = 'permissions.location_title';
  static const permissionsLocationBody = 'permissions.location_body';
  static const permissionsLocationPrivacy = 'permissions.location_privacy';
  static const permissionsAllowLocation = 'permissions.allow_location';
  static const permissionsNotNow = 'permissions.not_now';
  static const permissionsLimitedExp = 'permissions.limited_exp';
  static const permissionsLimitedExpBody = 'permissions.limited_exp_body';
  static const permissionsContWithoutLoc = 'permissions.cont_without_loc';
  static const permissionsCameraBody = 'permissions.camera_body';
  static const permissionsNotifsBody = 'permissions.notifs_body';
  static const permissionsNotifsAllow = 'permissions.notifs_allow';

  // ── Profile Setup (extra 2) ──────────────────────────────────────────────────
  static const profileSetupDobLabel = 'profile_setup.dob_label';
  static const profileSetupSelectDate = 'profile_setup.select_date';
  static const profileSetupCityLabel = 'profile_setup.city_label';
  static const profileSetupCityRequired = 'profile_setup.city_required';
  static const profileSetupFillAll = 'profile_setup.fill_all';
  static const profileSetupFailedCreate = 'profile_setup.failed_create';
  static const profileSetupGetToKnow = 'profile_setup.get_to_know';
  static const profileSetupTellUs = 'profile_setup.tell_us';
  static const profileSetupFullName = 'profile_setup.full_name';

  // ── Edit Profile (extra 2) ────────────────────────────────────────────────────
  static const editProfileBasicInfo = 'edit_profile.basic_info';
  static const editProfileNameHint = 'edit_profile.name_hint';
  static const editProfileBioHintLong = 'edit_profile.bio_hint_long';
  static const editProfileHomeCityLabel = 'edit_profile.home_city_label';
  static const editProfileHomeCityHint = 'edit_profile.home_city_hint';
  static const editProfileOccupationLabel = 'edit_profile.occupation_label';
  static const editProfileOccupationHint = 'edit_profile.occupation_hint';
  static const editProfileSaveProfile = 'edit_profile.save_profile';
  static const editProfilePreferences = 'edit_profile.preferences';
  static const editProfileTonightStatusSection = 'edit_profile.tonight_status_section';
  static const editProfileAvatarComingSoon = 'edit_profile.avatar_coming_soon';
  static const editProfileFailedLoad = 'edit_profile.failed_load';
  static const editProfileFailedSave = 'edit_profile.failed_save';
  static const editProfileLookingForLabel = 'edit_profile.looking_for_label';
  static const editProfileLookingForHint = 'edit_profile.looking_for_hint';
  static const editProfileIsRequired = 'edit_profile.is_required';

  // ── Notif Settings (extra 2) ─────────────────────────────────────────────────
  static const notifSafeArrival = 'notif_settings.safe_arrival';
  static const notifSafeArrivalSub = 'notif_settings.safe_arrival_sub';
  static const notifSettingsFailedLoad = 'notif_settings.failed_load';
  static const notifSettingsSavedBanner = 'notif_settings.saved_banner';

  // ── Safety Settings (extra 2) ────────────────────────────────────────────────
  static const safetyDeleteMyAccount = 'safety.delete_my_account';
  static const safetyDeletionRequested = 'safety.deletion_requested';
  static const safetyGhostHideSub = 'safety.ghost_hide_sub';
  static const safetyUnblockedUser = 'safety.unblocked_user';
  static const safetyFailedLoad = 'safety.failed_load';
  static const safetyFailedGhost = 'safety.failed_ghost';
  static const safetyFailedPrivacy = 'safety.failed_privacy';
  static const safetyFailedUnblock = 'safety.failed_unblock';
  static const safetyFailedSubmit = 'safety.failed_submit';
  static const safetyDataExportSoon = 'safety.data_export_soon';
  static const safetyPublicLabel = 'safety.public_label';
  static const safetyPublicDesc = 'safety.public_desc';
  static const safetyFriendsOnlyLabel = 'safety.friends_only_label';
  static const safetyFriendsOnlyDesc = 'safety.friends_only_desc';
  static const safetyPrivateLabel = 'safety.private_label';
  static const safetyPrivateDesc = 'safety.private_desc';

  // ── Room (extra 2) ───────────────────────────────────────────────────────────
  static const roomChatTab = 'room.chat_tab';
  static const roomWhosHereTab = 'room.whos_here_tab';
  static const roomPhotoWallTab = 'room.photo_wall_tab';
  static const roomVibeTab = 'room.vibe_tab';
  static const roomSaySomething = 'room.say_something';
  static const roomBeFirstSay = 'room.be_first_say';
  static const roomHereNow = 'room.here_now';
  static const roomIAmHere = 'room.i_am_here';
  static const roomNoOneCheckedIn = 'room.no_one_checked_in';
  static const roomBeFirst = 'room.be_first';
  static const roomPhotoComingSoon = 'room.photo_coming_soon';
  static const roomAddFirstPhoto = 'room.add_first_photo';
  static const roomNoActivePoll = 'room.no_active_poll';
  static const roomPopularVibes = 'room.popular_vibes';
  static const roomShareMomentTitle = 'room.share_moment_title';
  static const roomWhatHappening = 'room.what_happening';
  static const roomPostMoment = 'room.post_moment';
  static const roomRecentMoments = 'room.recent_moments';
  static const roomSubmitVote = 'room.submit_vote';
  static const roomCheckedIn = 'room.checked_in';
  static const roomCheckinFailed = 'room.checkin_failed';
  static const roomFailedSend = 'room.failed_send';
  static const roomVoteSuccess = 'room.vote_success';
  static const roomVoteFailed = 'room.vote_failed';
  static const roomMomentFailed = 'room.moment_failed';
  static const roomJustNow = 'room.just_now';
  static const roomMinAgo = 'room.min_ago';
  static const roomHourAgo = 'room.hour_ago';
  static const roomDayAgo = 'room.day_ago';
  static const roomOutNow = 'room.out_now';
  static const roomGoingOutSoon = 'room.going_out_soon';
  static const roomStayingIn = 'room.staying_in';
  static const roomPollLabel = 'room.poll_label';
  static const roomTheRoomDefault = 'room.the_room_default';

  // ── Safe Arrival (extra 2) ───────────────────────────────────────────────────
  static const safeArrivalFriendsSection = 'safe_arrival.friends_section';
  static const safeArrivalAddBtn = 'safe_arrival.add_btn';
  static const safeArrivalAddFriendDialog = 'safe_arrival.add_friend_dialog';
  static const safeArrivalSearchHint = 'safe_arrival.search_hint';
  static const safeArrivalWillNotify = 'safe_arrival.will_notify';
  static const safeArrivalRecentSection = 'safe_arrival.recent_section';
  static const safeArrivalNoRecent = 'safe_arrival.no_recent';
  static const safeArrivalArrivedSafe = 'safe_arrival.arrived_safe';
  static const safeArrivalEmergencySection = 'safe_arrival.emergency_section';
  static const safeArrivalCall911 = 'safe_arrival.call_911';
  static const safeArrivalCall112 = 'safe_arrival.call_112';
  static const safeArrivalIAmHome = 'safe_arrival.i_am_home';
  static const safeArrivalRecordingState = 'safe_arrival.recording';
  static const safeArrivalRecordedTitle = 'safe_arrival.recorded_title';
  static const safeArrivalNotifyMsg = 'safe_arrival.notify_msg';
  static const safeArrivalGreat = 'safe_arrival.great';
  static const safeArrivalFailedRecord = 'safe_arrival.failed_record';
  static const safeArrivalFriendAdded = 'safe_arrival.friend_added';
  static const safeArrivalAddFriendPrompt = 'safe_arrival.add_friend_prompt';
  static const safeArrivalLetFriendsKnow = 'safe_arrival.let_friends_know';

  // ── Night Recap (extra 2) ────────────────────────────────────────────────────
  static const recapNightTitle = 'recap.night_title';
  static const recapActivitiesCount = 'recap.activities_count';
  static const recapStartGoingOut = 'recap.start_going_out';
  static const recapVenueCheckin = 'recap.venue_checkin';
  static const recapMessageSent = 'recap.message_sent';
  static const recapSwarmJoined = 'recap.swarm_joined';
  static const recapGiftSent = 'recap.gift_sent';
  static const recapActivity = 'recap.activity';
  static const recapSentMessage = 'recap.sent_message';
  static const recapVenueDefault = 'recap.venue_default';
  static const recapSwarmDefault = 'recap.swarm_default';
  static const recapGiftDefault = 'recap.gift_default';
  static const recapMessagesLabel = 'recap.messages_label';
  static const recapSwarmsLabel = 'recap.swarms_label';

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // English fallback — used when Supabase has no translation for the active lang
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Map<String, String> englishFallback = {
    // Common
    ok: 'OK',
    cancel: 'Cancel',
    save: 'Save',
    close: 'Close',
    done: 'Done',
    next: 'Next',
    skip: 'Skip',
    back: 'Back',
    confirm: 'Confirm',
    error: 'Error',
    loading: 'Loading…',
    retry: 'Retry',
    send: 'Send',
    search: 'Search',
    add: 'Add',
    remove: 'Remove',
    share: 'Share',
    block: 'Block',
    unblock: 'Unblock',
    report: 'Report',
    viewAll: 'View All',
    unknownUser: 'Unknown user',
    unknown: 'Unknown',
    optional: 'optional',
    appName: 'Barfliz',
    version: 'Barfliz v1.0.0',

    // Auth
    signInTitle: 'Welcome back',
    signInSubtitle: 'Sign in to your account',
    signInButton: 'Sign In',
    signInForgot: 'Forgot password?',
    signInNoAccount: "Don't have an account?",
    signInGoSignUp: 'Sign Up',
    signUpTitle: 'Create account',
    signUpSubtitle: 'Join Barfliz tonight',
    signUpButton: 'Create Account',
    signUpHaveAccount: 'Already have an account?',
    signUpGoSignIn: 'Sign In',
    signInEnterEmail: 'Please enter an email',
    signInForgotDesc: "Enter your email address and we'll send you a link to reset your password.",
    signInResetEmailSent: 'Password reset email sent!',
    signInSendResetLink: 'Send Reset Link',
    signUpAgreeTerms: 'Please agree to the Terms of Service and Privacy Policy',
    fieldEmail: 'Email',
    fieldPassword: 'Password',
    fieldName: 'Full name',
    fieldConfirmPass: 'Confirm password',
    signOut: 'Sign Out',
    signOutTitle: 'Sign Out',
    signOutConfirm: 'Are you sure you want to sign out?',

    // Navigation
    navHome: 'Home',
    navMap: 'Map',
    navMessages: 'Messages',
    navProfile: 'Profile',
    navMore: 'More',
    moreFriends: 'Friends',
    moreHistory: 'History',
    morePayments: 'Payments',
    moreLeaderboard: 'Leaderboard',
    moreNightRecap: 'Night Recap',
    moreNotifications: 'Notifications',

    // Onboarding
    onboardingSkip: 'Skip',
    onboardingNext: 'Next',
    onboardingStart: "Let's Go",

    // Permissions
    permissionsTitle: 'Permissions',
    permissionsSubtitle: 'Allow the following to get the most out of Barfliz',
    permissionsLocation: 'Location',
    permissionsLocSubtitle: 'Find venues and people near you',
    permissionsNotifs: 'Notifications',
    permissionsNotifsSubtitle: 'Get updates on friends and events',
    permissionsAllow: 'Allow',
    permissionsSkip: 'Skip for now',
    permissionsContinue: 'Continue',

    // Home
    homeTitle: 'Home',
    homeGoodEvening: 'Good evening',
    homeTonightStatus: "Tonight's Status",
    homeGoingOut: 'Going Out',
    homeMaybe: 'Maybe',
    homeStayingIn: 'Staying In',
    homeOutNow: 'Out Now',
    homePopularVenues: 'Popular Venues',
    homeActiveSwarms: 'Active Swarms',
    homeQuickActions: 'Quick Actions',
    homeNearbyPeople: 'Nearby People',
    homeSceneTonight: "Tonight's Scene",
    homeDdTonight: 'DD Tonight',
    homeSafeArrival: 'Safe Arrival',
    homeCheckins: 'Check-ins',
    homeFriends: 'Friends',
    homeSwarms: 'Swarms',
    homeLevel: 'Level',
    homeXp: 'XP',
    homeStreak: 'Streak',
    homeNoVenues: 'No venues nearby',
    homeNoSwarms: 'No active swarms',
    homeNoNearby: 'No one nearby right now',
    homePeopleOut: 'people out tonight',
    homeCheckIn: 'Check In',
    homeSendGift: 'Send Gift',
    homeMapView: 'Map View',
    homeCreateSwarm: 'Create Swarm',

    // Map
    mapTitle: 'Map',
    mapVenues: 'Venues',
    mapPeople: 'People',
    mapFilterAll: 'All',
    mapFilterBars: 'Bars',
    mapFilterClubs: 'Clubs',
    mapFilterRestaurants: 'Restaurants',
    mapNoVenues: 'No venues in this area',
    mapOpenInMaps: 'Open in Maps',
    mapGetDirections: 'Get Directions',
    mapCheckIn: 'Check In',

    // Messages
    messagesTitle: 'Messages',
    messagesEmpty: 'No conversations yet',
    messagesEmptySub: 'Start chatting with friends to see messages here',
    messagesHint: 'Type a message…',
    messagesYou: 'You',
    chatTitle: 'Chat',
    chatInputHint: 'Message…',
    chatSend: 'Send',

    // Profile
    profileTitle: 'Profile',
    profileEdit: 'Edit Profile',
    profileFollowers: 'Followers',
    profileFollowing: 'Following',
    profileFriends: 'Friends',
    profileBio: 'Bio',
    profileInterests: 'Interests',
    profileCheckins: 'Check-ins',
    profileXp: 'XP',
    profileLevel: 'Level',
    profileAddFriend: 'Add Friend',
    profileSendGift: 'Send Gift',
    profileSendMessage: 'Message',
    profileBlockUser: 'Block User',
    profileReportUser: 'Report User',

    // Friends
    friendsTitle: 'Friends',
    friendsTabFriends: 'Friends',
    friendsTabRequests: 'Requests',
    friendsTabFind: 'Find',
    friendsEmpty: 'No friends yet',
    friendsEmptySub:
        'Use Find Friends to connect with people going out tonight',
    friendsNoRequests: 'No pending requests',
    friendsNoRequestsSub: 'Friend requests will appear here',
    friendsSearchHint: 'Search people…',
    friendsAccept: 'Accept',
    friendsDecline: 'Decline',
    friendsPending: 'Pending',
    friendsRemove: 'Remove Friend',
    friendsAddFriend: 'Add Friend',
    friendsRequestSent: 'Request Sent',
    friendsAlready: 'Friends',
    friendsMutualCount: 'mutual friends',
    friendsFindPeople: 'Find People',

    // Notifications
    notificationsTitle: 'Notifications',
    notificationsEmpty: 'No notifications yet',
    notificationsMarkAll: 'Mark all as read',
    notificationsToday: 'Today',
    notificationsEarlier: 'Earlier',

    // Leaderboard
    leaderboardTitle: 'Leaderboard & XP',
    leaderboardTab: 'Leaderboard',
    challengesTab: 'Challenges',
    leaderboardMyStats: 'My Stats',
    leaderboardRank: 'Rank',
    leaderboardXp: 'XP',
    leaderboardStreak: 'Streak',
    leaderboardCheckins: 'Check-ins',
    leaderboardEmpty: 'No data yet',
    challengesEmpty: 'No challenges available',
    challengeCompleted: 'Completed',
    challengeInProgress: 'In Progress',
    challengeLocked: 'Locked',
    challengeXpReward: 'XP reward',

    // Settings
    settingsTitle: 'Settings',
    settingsAccount: 'Account',
    settingsSocial: 'Social',
    settingsPrivacy: 'Privacy & Safety',
    settingsPayments: 'Payments & Premium',
    settingsMore: 'More',
    settingsEditProfile: 'Edit Profile',
    settingsEditProfileSub: 'Update your name, bio, photos',
    settingsAppearance: 'Appearance',
    settingsDarkOn: 'Dark mode on',
    settingsLightOn: 'Light mode on',
    settingsLanguage: 'Language',
    settingsLanguageSub: 'Change app language',
    settingsFriends: 'Friends',
    settingsFriendsSub: 'Manage your friend list',
    settingsNotifications: 'Notifications',
    settingsNotifsSub: 'Manage notification preferences',
    settingsSafety: 'Safety & Security',
    settingsSafetySub: 'Ghost mode, safe arrival, emergency contacts',
    settingsBlocked: 'Blocked Users',
    settingsBlockedSub: 'Manage users you have blocked',
    settingsPremium: 'Go Premium',
    settingsPremiumSub: 'Unlock all features',
    settingsPaymentsTitle: 'Payments',
    settingsPaymentsSub: 'Send money, LushCoin balance',
    settingsMyGifts: 'My Gifts',
    settingsMyGiftsSub: 'View received gifts',
    settingsHistory: 'Activity History',
    settingsHistorySub: 'Your nightlife history',
    settingsLeaderboard: 'Leaderboard & XP',
    settingsLeaderboardSub: 'Your rank and achievements',
    settingsHelp: 'Help Center',
    settingsHelpSub: 'FAQs and support',
    settingsPrivacyPolicy: 'Privacy Policy',
    settingsPrivacySub: 'How we handle your data',
    settingsTerms: 'Terms of Service',

    // Language
    languageTitle: 'Language',
    languageSelect: 'Select Language',

    // Blocked users
    blockedTitle: 'Blocked Users',
    blockedEmpty: 'No blocked users',
    blockedEmptySub:
        "Users you block won't be able to see your profile or message you.",
    blockedOn: 'Blocked',
    blockedUnblock: 'Unblock',
    blockedLoadError: 'Could not load blocked users.',
    blockedUnblockOk: 'Unblocked.',
    blockedUnblockError: 'Could not unblock. Please try again.',

    // Send gift
    giftTitle: 'Send a Gift',
    giftTitleTo: 'Send Gift to',
    giftChooseDrink: 'Choose a drink',
    giftAmount: 'Amount',
    giftMessageHint: 'Add a message (optional)',
    giftSendButton: 'Send Gift',
    giftSentSuccess: 'Gift sent!',
    giftSendError: 'Failed to send gift',
    giftDrinkBeer: 'Beer',
    giftDrinkWine: 'Wine',
    giftDrinkCocktail: 'Cocktail',
    giftDrinkShot: 'Shot',
    giftDrinkCustom: 'Custom',

    // Gifts received
    giftsTitle: 'My Gifts',
    giftsEmpty: 'No gifts yet',
    giftsEmptySub: 'Gifts from friends will appear here',
    giftsFrom: 'From',
    giftsPending: 'Pending',
    giftsAccepted: 'Accepted',

    // History
    historyTitle: 'Activity History',
    historyTabActivity: 'Activity',
    historyTabVisits: 'Visits',
    historyEmpty: 'No activity yet',
    historyEmptySub: 'Check in at venues to start your history',

    // Payments
    paymentsTitle: 'Payments',
    paymentsTabOverview: 'Overview',
    paymentsTabSend: 'Send',
    paymentsTabHistory: 'History',
    paymentsBalance: 'Balance',
    paymentsLushCoins: 'LushCoin Balance',
    paymentsSendMoney: 'Send Money',
    paymentsEmpty: 'No transactions yet',

    // Premium
    premiumTitle: 'Go Premium',
    premiumSubtitle: 'Unlock the full Barfliz experience',
    premiumMonthly: 'Monthly',
    premiumYearly: 'Yearly',
    premiumGetPremium: 'Get Premium',
    premiumAlreadySub: "You're already subscribed!",
    premiumFeaturesTitle: 'Premium Features',

    // Discover
    discoverTitle: 'Discover',
    discoverNoResults: 'No more people to show',
    discoverLike: 'Like',
    discoverSkip: 'Skip',
    discoverMatch: "It's a Match!",

    // People Nearby
    peopleTitle: 'People Nearby',
    peopleEmpty: 'No one nearby right now',
    peopleEmptySub: 'Check back later when more people are going out',
    peopleFilterAll: 'All',
    peopleFilterOut: 'Out Now',
    peopleFilterGoing: 'Going Out',
    peopleSearchHint: 'Search people…',
    peopleNearby: 'nearby',
    peopleAddFriend: 'Add Friend',

    // Swarms
    swarmsTitle: 'Swarms',
    swarmsCreate: 'Create Swarm',
    swarmsJoin: 'Join',
    swarmsEmpty: 'No active swarms',
    swarmsEmptySub: 'Create a swarm to invite friends to hang out',
    swarmsMembers: 'members',
    swarmsLeave: 'Leave Swarm',

    // Safety
    safetyTitle: 'Safety & Security',
    safetyGhostMode: 'Ghost Mode',
    safetyGhostSub: 'Hide your location and profile from others',
    safetySafeArrival: 'Safe Arrival',
    safetySafeArrivalSub: 'Let contacts know you arrived safely',
    safetyEmergency: 'Emergency Contacts',
    safetyEmergencySub: 'People to notify in an emergency',
    safetyBlockedUsers: 'Blocked Users',

    // Notifications settings
    notifSettingsTitle: 'Notification Settings',
    notifSettingsSaved: 'Settings saved',

    // Edit profile
    editProfileTitle: 'Edit Profile',
    editProfileSave: 'Save',
    editProfileName: 'Name',
    editProfileBio: 'Bio',
    editProfileDob: 'Date of Birth',
    editProfileInterests: 'Interests',
    editProfilePhoto: 'Change Photo',

    // Night Recap
    recapTitle: 'Night Recap',
    recapSubtitle: "Here's how your night went",
    recapVenues: 'Venues Visited',
    recapPeople: 'People Met',
    recapXpEarned: 'XP Earned',

    // Room
    roomTitle: 'The Room',
    roomTabChat: 'Chat',
    roomTabPeople: 'People',
    roomTabPhotos: 'Photos',
    roomTabMoments: 'Moments',
    roomInputHint: 'Message the room…',

    // Music
    musicTitle: 'Music',
    musicSearchHint: 'Search songs, artists…',
    musicLike: 'Like',
    musicBy: 'by',
    musicShare: 'Share',
    musicShared: 'Shared!',
    musicEmpty: 'No music shared yet',

    // Profile setup
    profileSetupTitle: 'Set Up Your Profile',
    profileSetupSubtitle: 'Tell us a bit about yourself',
    profileSetupContinue: 'Continue',

    // Safe Arrival
    safeArrivalTitle: 'Safe Arrival',
    safeArrivalChecked: 'Checked In Safely',
    safeArrivalNotify: 'Notify my contacts',

    // Report
    reportTitle: 'Report',
    reportSubmit: 'Submit Report',
    reportSuccess: 'Report submitted. Thank you.',
    reportReasonSpam: 'Spam',
    reportReasonHarassment: 'Harassment',
    reportReasonHate: 'Hate Speech',
    reportReasonSexual: 'Sexual Content',
    reportReasonViolence: 'Violence',
    reportReasonUnderage: 'Underage User',
    reportReasonImpersonation: 'Impersonation',
    reportReasonSafety: 'Safety Concern',
    reportReasonOther: 'Other',

    // First run tour
    tourStep1Title: "Tonight's Status",
    tourStep1Body: 'Let friends know if you\'re going out tonight',
    tourStep2Title: 'Live Map',
    tourStep2Body: 'See venues and friends near you in real time',
    tourStep3Title: 'Swarms',
    tourStep3Body: 'Create or join group hangouts at your favourite spots',
    tourStep4Title: 'Friends & Chat',
    tourStep4Body: 'Connect with friends and keep the night going',
    tourLetsGo: "Let's Go!",

    // Dialogs
    helpTitle: 'Help Center',
    helpFaq: 'Frequently Asked Questions',
    helpQ1: 'Q: How do I find people nearby?\nA: Use the People Nearby screen or the map to discover people going out tonight.',
    helpQ2: 'Q: What is a Swarm?\nA: A Swarm is a group hangout you can create or join to meet people at a venue.',
    helpQ3: 'Q: How do I earn XP?\nA: Check in at venues, send messages, join swarms, and send gifts to earn XP.',
    helpQ4: 'Q: What is Ghost Mode?\nA: Ghost mode hides your location and profile from other users.',
    privacyTitle: 'Privacy Policy',
    termsTitle: 'Terms of Service',

    // Home (extra)
    homeGoingOut2: 'Going Out Soon',
    homeAppTagline: 'Going out made easy',
    homeEditStatus: 'Edit Status',
    homeVibes: 'Vibes',
    homeDrinks: 'Drinks',
    homeLushCoins: 'Lush Coins',
    homeYourStats: 'Your Stats',
    homeNoOneTonightScene: 'No one is out right now. Be the first!',
    homeNoVenuesFound: 'No venues found',
    homeNoActiveSwarmsLong: 'No active swarms right now',
    homeDdToggleTitle: "I'm the DD tonight 🚗",
    homeDdToggleSub: 'Let your friends know you can drive safely',
    homeCheckInSafeArrival: 'Check In Safe Arrival',
    homeUpdateStatus: 'Update Tonight Status',
    homeSaveStatus: 'Save Status',
    homeSafeArrivalRecorded: 'Safe arrival recorded!',
    homeCouldNotLoadProfile: 'Could not load profile',
    homeProfileNotFound: 'Profile not found',
    homeCouldNotLoadPeople: 'Could not load people',
    homeCouldNotLoadVenues: 'Could not load venues',
    homeCouldNotLoadSwarms: 'Could not load swarms',
    homeSeeAll: 'See All',
    homeQuickCreateSwarm: 'Create Swarm',
    homeQuickSendMessage: 'Send Message',
    homeQuickFindVenues: 'Find Venues',
    homeQuickFindPeople: 'Find People',
    homeQuickViewHistory: 'View History',
    homeQuickFriends: 'Friends',
    homeStatNearby: 'Nearby',
    homeStatOutNow: 'Out Now',
    homeStatVenues: 'Venues',
    homeMaxAttendees: 'max',

    // Auth (extra)
    authValidEmailRequired: 'Please enter your email',
    authValidEmailFormat: 'Please enter a valid email',
    authPasswordRequired: 'Please enter your password',
    authPasswordMinLength: 'Password must be at least 6 characters',
    authConfirmPasswordRequired: 'Please confirm your password',
    authPasswordsNoMatch: 'Passwords do not match',
    authAgreeToTerms: 'Please agree to the Terms of Service and Privacy Policy',
    authIAgree: 'I agree to the ',
    authAnd: ' and ',
    authSignUpFailed: 'Sign up failed',
    authSignInFailed: 'Sign in failed',
    authForgotPasswordHint: 'Enter your email to reset your password',
    authPasswordResetSent: 'Password reset email sent!',
    authSendResetLink: 'Send Reset Link',

    // Messages (extra)
    messagesNoMsgYet: 'No messages yet',
    messagesStartConvo: 'Start a conversation with someone nearby!',
    chatNoMsgYet: 'No messages yet',
    chatSayHello: 'Say hello!',
    chatFailedSend: 'Failed to send',
    chatTypeMsg: 'Type a message...',
    chatNotLoggedIn: 'Not logged in',

    // Notifications (extra)
    notificationsUnread: 'unread',
    notificationsMarkAllRead: 'Mark all read',
    notificationsAllCaughtUp: "You're all caught up!",
    notificationsError: 'Error',

    // Profile (extra)
    profileErrorLoading: 'Error loading profile',
    profileNotFound: 'No profile found',
    profileYearsOld: 'years old',
    profileTonightStatus: 'Tonight Status',
    profileChange: 'Change',
    profileAboutMe: 'About Me',
    profileNoBio: 'No bio yet. Tell people about yourself!',
    profileVibeTags: 'Vibe Tags',
    profileFavoritesDrinks: 'Favorite Drinks',
    profilePremium: 'Premium',
    profileYes: 'Yes',
    profileNo: 'No',

    // Map (extra)
    mapLoadingVenues: 'Loading venues...',
    mapVenuesNearby: 'venues nearby',
    mapTapMarker: 'Tap a marker for details',
    mapDirections: 'Directions',
    mapCheckInVenue: 'Check In',

    // Discover (extra)
    discoverNoOne: 'No one to discover right now',
    discoverCheckBack: 'Check back later when more people are going out!',
    discoverRefresh: 'Refresh',
    discoverYouLiked: 'You liked',
    discoverError: 'Error',

    // People (extra)
    peopleFilterDd: 'DD Tonight',
    peoplePerson: 'person',
    peoplePeople: 'people',
    peopleOutTonight: 'out tonight',
    peopleChat: 'Chat',
    peopleFriends: 'Friends',
    peoplePending: 'Pending',
    peopleAddFriendBtn: 'Add Friend',
    peopleSomethingWrong: 'Something went wrong',
    peopleNoOneNearby: 'No one nearby yet',
    peopleNoFilter: 'No one matches this filter',
    peoplePullRefresh: 'Pull down to refresh or try a different filter.',
    peopleSearchHintName: 'Search by name...',

    // Swarms (extra)
    swarmsComingSoon: 'Group meetups coming soon',
    swarmsCreateNew: 'Create a new group meetup',
    swarmsStartsInMinutes: 'Starts in',
    swarmsStartsInHours: 'Starts in',
    swarmsMax: 'max',
    swarmsNameLabel: 'Swarm Name',
    swarmsNameHint: 'e.g. Downtown bar crawl',
    swarmsNameRequired: 'Please enter a swarm name',
    swarmsDescLabel: 'Description (optional)',
    swarmsDescHint: 'What\'s the plan?',
    swarmsStartTimeLabel: 'Start Time',
    swarmsPickTime: 'Pick a time',
    swarmsMaxAttendeesLabel: 'Max Attendees',
    swarmsVibeTagsLabel: 'Vibe Tags',
    swarmsCreateSuccess: 'Swarm created! 🎉',
    swarmsCreateFailed: 'Failed to create swarm',
    swarmsPublish: 'Publish Swarm',

    // History (extra)
    historyVisitsEmpty: 'No venue visits yet',
    historyVisitsEmptySub: 'Check in at a venue to see it here',
    historyTypeCheckin: 'Check-in',
    historyTypeMessage: 'Message',
    historyTypeSwarm: 'Swarm',
    historyTypeFriend: 'Friend',
    historyTypeGift: 'Gift',

    // Payments (extra)
    paymentsAddCoins: 'Add Coins',
    paymentsLinkMethod: 'Link Payment Method',
    paymentsRequestPayment: 'Request Payment',
    paymentsInvalidAmount: 'Please enter a valid amount',
    paymentsNoteLabel: 'Note (optional)',
    paymentsNoteHint: "What's it for?",
    paymentsHistoryEmptySub: 'Your payment history will appear here',
    paymentsSearchHint: 'Search people by name...',
    paymentsAmountUsd: 'Amount (USD)',
    paymentsLinked: 'linked',
    paymentsSendingTo: 'Sending to',
    paymentsCoinsAvailable: 'coins available',
    paymentsPaymentMethod: 'Payment Method',
    paymentsNoMethodLinked: 'No method linked',
    paymentsLinkCard: 'Link Card',
    paymentsTotalSent: 'Total Sent',
    paymentsTotalReceived: 'Total Received',
    paymentsTransactions: 'Transactions',
    paymentsNoTransactions: 'No transactions yet',
    paymentsSent: 'Payment Sent',
    paymentsReceived: 'Payment Received',
    paymentsSendTo: 'Send to',
    paymentsAmount: 'Amount',
    paymentsSendPayment: 'Send Payment',
    paymentsPaymentSent: 'Payment sent!',
    paymentsPaymentReceived: 'Payment received',
    paymentsComingSoon: 'Coming Soon',
    paymentsStripeNote: 'Secure payments powered by Stripe',
    paymentsVenmoComingSoon: 'Venmo setup coming soon',
    paymentsPaypalComingSoon: 'PayPal setup coming soon',
    paymentsCashappComingSoon: 'CashApp setup coming soon',
    paymentsPaymentSentTo: 'Payment sent to',
    paymentsFailedSend: 'Failed to send payment',

    // Gifts (extra)
    giftsMyGifts: 'My Gifts',
    giftsNoGiftsYet: 'No gifts yet',
    giftsNoGiftsSub: 'Send or receive virtual drinks',

    // Leaderboard (extra)
    leaderboardSignInStats: 'Sign in to see your stats',
    leaderboardYourStats: 'Your Stats',
    leaderboardNightStreak: 'night streak',
    leaderboardNoChallenges: 'No challenges yet',
    leaderboardCompleteXp: 'Complete challenges to earn XP',
    leaderboardXpEarned: 'XP earned',
    leaderboardFromChallenges: 'from completed challenges',
    leaderboardError: 'Error',
    leaderboardCheckIns: 'check-ins',

    // Friends (extra)
    friendsMessage: 'Message',
    friendsAcceptBtn: 'Accept',
    friendsDeclineBtn: 'Decline',
    friendsAddFriendBtn: 'Add Friend',
    friendsFriendsLabel: 'Friends',
    friendsPendingLabel: 'Pending',
    friendsNoFriendsTitle: 'No friends yet',
    friendsNoFriendsSub: 'Use "Find Friends" to connect with people nearby.',
    friendsNoPendingTitle: 'No pending requests',
    friendsNoPendingSub: 'Friend requests will appear here.',
    friendsNoOneFound: 'No one found',
    friendsNoOneFoundSub: 'Try a different search or check back later.',
    friendsSomethingWrong: 'Something went wrong',
    friendsSearchHintName: 'Search by name...',

    // Premium (extra)
    premiumComingSoon: 'Coming Soon',
    premiumComingSoonMsg:
        'Premium subscriptions will be available soon!\n\nWe\'re setting up secure payment processing with Stripe.',
    premiumNotifyMe: 'Notify Me',
    premiumNotifyConfirm: "You'll be notified when Premium launches!",
    premiumFeatureUnlimitedSwipes: 'Unlimited Swipes',
    premiumFeatureUnlimitedSwipesSub: 'Never run out of potential matches',
    premiumFeatureSeeWhoLikes: 'See Who Likes You',
    premiumFeatureSeeWhoLikesSub: 'Know who wants to meet you',
    premiumFeatureAdvancedFilters: 'Advanced Filters',
    premiumFeatureAdvancedFiltersSub: "Find exactly who you're looking for",
    premiumFeatureNoAds: 'No Ads',
    premiumFeatureNoAdsSub: 'Enjoy an ad-free experience',

    // Sign-in (extra)
    signInValidEmail: 'Please enter your email',
    signInValidEmailFormat: 'Please enter a valid email',
    signInPasswordRequired: 'Please enter your password',

    // Onboarding (extra)
    onboardingSlide1Title: 'Find your\nDrinking Partner !',
    onboardingSlide1Sub: 'Get bored drinking alone,\nfind new drinking partner',
    onboardingSlide2Title: 'Real Drinks with\nReal Friends !',
    onboardingSlide2Sub: 'Enjoy Your drink with new\nfriends',
    onboardingSlide3Title: 'Best Social App To\nMake New Friends !',
    onboardingSlide3Sub: 'Find people with the same\ninterest as you',
    onboardingGetStarted: 'Get Started',
    onboardingAlreadyAccount: 'Already have an account? ',
    onboardingSignIn: 'Sign in',

    // Profile Setup (extra)
    profileSetupNameLabel: 'Name',
    profileSetupNameHint: 'Your display name',
    profileSetupNameRequired: 'Please enter your name',
    profileSetupBioLabel: 'Bio',
    profileSetupBioHint: 'Tell us about yourself',
    profileSetupSaved: 'Profile saved!',
    profileSetupError: 'Failed to save profile',

    // Safe Arrival (extra)
    safeArrivalStaySafe: 'Stay Safe Tonight',
    safeArrivalSafeRecorded: 'Safe arrival recorded!',
    safeArrivalNotifyContacts: 'Notify my contacts',
    safeArrivalAddContact: 'Add Contact',
    safeArrivalEmergency: 'Emergency',
    safeArrivalEmergencyContacts: 'Emergency Contacts',
    safeArrivalNoContacts: 'No emergency contacts added',
    safeArrivalCheckinNow: 'Check In Now',

    // Edit Profile (extra)
    editProfileSaved: 'Profile updated!',
    editProfileError: 'Failed to save profile',
    editProfileNameLabel: 'Name',
    editProfileBioLabel: 'Bio',
    editProfileDobLabel: 'Date of Birth',
    editProfileStatusLabel: 'Tonight Status',
    editProfileVibeTags: 'Vibe Tags',
    editProfileFavDrinks: 'Favourite Drinks',
    editProfileStatusOutNow: 'Out Now',
    editProfileStatusGoing: 'Going Out Soon',
    editProfileStatusStaying: 'Staying In',

    // Safety Settings (extra)
    safetyPrivacy: 'Privacy',
    safetyGhostModeTitle: 'Ghost Mode',
    safetyProfileVisibility: 'Profile Visibility',
    safetyVisibilityEveryone: 'Everyone',
    safetyVisibilityFriends: 'Friends Only',
    safetyVisibilityNone: 'No one',
    safetyBlockedUsersTitle: 'Blocked Users',
    safetyNoBlocked: 'No blocked users',
    safetyAccount: 'Account',
    safetyDeleteAccount: 'Delete Account',
    safetyDeleteAccountSub: 'Permanently delete your account and all data',
    safetyYourData: 'Your Data',
    safetyDownloadData: 'Download My Data',
    safetyDownloadDataSub: 'Get a copy of all your data',
    safetyDeleteConfirmTitle: 'Delete Account',
    safetyDeleteConfirmMsg:
        'This action is permanent and cannot be undone. Are you sure?',
    safetyDeleteConfirmBtn: 'Delete',
    safetyDownloadComingSoon: 'Data download coming soon!',

    // Notif Settings (extra)
    notifSettingsSocial: 'Social',
    notifSettingsLocation: 'Location & Activity',
    notifSettingsOther: 'Other',
    notifSettingsSaveError: 'Failed to save settings',
    notifFriendReq: 'Friend Requests',
    notifFriendReqSub: 'When someone sends you a friend request',
    notifFriendAccepted: 'Friend Accepted',
    notifFriendAcceptedSub: 'When someone accepts your friend request',
    notifMessages: 'Messages',
    notifMessagesSub: 'When you receive a new message',
    notifGifts: 'Gifts',
    notifGiftsSub: 'When someone sends you a virtual drink',
    notifNearbyFriends: 'Nearby Friends',
    notifNearbyFriendsSub: 'When friends are nearby',
    notifCheckins: 'Check-ins',
    notifCheckinsSub: 'When friends check in at a venue',
    notifSwarms: 'Swarms',
    notifSwarmsSub: 'When swarms start near you',
    notifPromo: 'Promotions',
    notifPromoSub: 'Venue deals and app updates',
    notifWeekly: 'Weekly Digest',
    notifWeeklySub: 'Summary of your weekly activity',

    // Night Recap (extra)
    recapTimeline: 'Timeline',
    recapShareBtn: 'Share Night Recap',
    recapNothingYet: 'Nothing to recap yet!',
    recapFindVenues: 'Find Venues',
    recapNightRoute: 'Night Route',
    recapCheckins: 'Check-ins',
    recapGiftsSent: 'Gifts sent',
    recapXp: 'XP',

    // Music (extra)
    musicSearchTitle: 'Search Music',
    musicSearchHintFull: 'Search songs, artists...',
    musicStartTyping: 'Start typing to search',
    musicNoResults: 'No results found',
    musicError: 'Error',
    musicShareTitle: 'Share a Song',
    musicShareHint: 'Search on Apple Music...',
    musicSharedOk: 'Song shared successfully!',
    musicShareFailed: 'Failed to share',
    musicSearchFailed: 'Search failed',
    musicTabDiscover: 'Discover',
    musicTabMyShares: 'My Shares',
    musicNoMyShares: "You haven't shared any music yet",

    // Room (extra)
    roomSendPhoto: 'Send Photo',
    roomPresenceTitle: 'Who\'s Here',
    roomPhotoWall: 'Photo Wall',
    roomVibeTitle: 'Vibes',
    roomNoMessages: 'No messages yet',
    roomNoPhotos: 'No photos yet',
    roomNoMoments: 'No moments yet',

    // Permissions (extra)
    permissionsLocationDenied: 'Location Denied',
    permissionsLocationDeniedSub:
        'Please enable location in Settings to find venues and people near you',
    permissionsOpenSettings: 'Open Settings',
    permissionsCameraTitle: 'Camera Access',
    permissionsCameraSubtitle: 'Allow camera access to share photos',
    permissionsCameraAllow: 'Allow Camera',
    permissionsNotifsScreenTitle: 'Stay in the Loop',
    permissionsNotifsScreenSubtitle:
        'Enable notifications to get updates on friends and events',

    // Permissions (extra 2)
    permissionsLocationTitle: 'Enable Location to\nConnect in Real Life',
    permissionsLocationBody:
        'Barfliz uses your location to place you inside real venues so you can meet and interact with others around you in real time.',
    permissionsLocationPrivacy:
        'Your exact location is never shared publicly. You control who sees you.',
    permissionsAllowLocation: 'Allow Location',
    permissionsNotNow: 'Not Now',
    permissionsLimitedExp: 'Limited Experience',
    permissionsLimitedExpBody:
        "Without location access, you won't be able to:\n\n- Auto check-in to venues\n- See who's nearby\n- Get venue recommendations\n- Use real-time social features",
    permissionsContWithoutLoc: 'Continue Without Location',
    permissionsCameraBody:
        'Used for profile photos and sharing moments in venues. Show others your best side!',
    permissionsNotifsBody:
        'Get notified when friends arrive at venues, when you receive messages, and when swarms are happening nearby.',
    permissionsNotifsAllow: 'Allow Notifications',

    // Profile Setup (extra 2)
    profileSetupDobLabel: 'Date of Birth',
    profileSetupSelectDate: 'Select date',
    profileSetupCityLabel: 'City',
    profileSetupCityRequired: 'Please enter your city',
    profileSetupFillAll: 'Please fill in all fields',
    profileSetupFailedCreate: 'Failed to create profile',
    profileSetupGetToKnow: "Let's get to know you!",
    profileSetupTellUs: 'Tell us about yourself',
    profileSetupFullName: 'Full Name',

    // Edit Profile (extra 2)
    editProfileBasicInfo: 'Basic Info',
    editProfileNameHint: 'Your name',
    editProfileBioHintLong: 'Tell people about yourself...',
    editProfileHomeCityLabel: 'Home City',
    editProfileHomeCityHint: 'Where are you from?',
    editProfileOccupationLabel: 'Occupation',
    editProfileOccupationHint: 'What do you do?',
    editProfileSaveProfile: 'Save Profile',
    editProfilePreferences: 'Preferences',
    editProfileTonightStatusSection: 'Tonight Status',
    editProfileAvatarComingSoon: 'Avatar upload coming soon',
    editProfileFailedLoad: 'Failed to load profile',
    editProfileFailedSave: 'Failed to save',
    editProfileLookingForLabel: 'Looking For',
    editProfileLookingForHint: 'Select an option',
    editProfileIsRequired: 'is required',

    // Notif Settings (extra 2)
    notifSafeArrival: 'Safe Arrival Alerts',
    notifSafeArrivalSub: 'When safety friends arrive home',
    notifSettingsFailedLoad: 'Failed to load notification preferences',
    notifSettingsSavedBanner: 'Notification preferences saved!',

    // Safety Settings (extra 2)
    safetyDeleteMyAccount: 'Delete My Account',
    safetyDeletionRequested:
        'Account deletion requested. You will receive a confirmation email.',
    safetyGhostHideSub: 'Hide your location and profile from discovery',
    safetyUnblockedUser: 'unblocked',
    safetyFailedLoad: 'Failed to load settings',
    safetyFailedGhost: 'Failed to update ghost mode',
    safetyFailedPrivacy: 'Failed to update privacy',
    safetyFailedUnblock: 'Failed to unblock',
    safetyFailedSubmit: 'Failed to submit request',
    safetyDataExportSoon: 'Data export requested - check your email',
    safetyPublicLabel: 'Public',
    safetyPublicDesc: 'Everyone can see your profile',
    safetyFriendsOnlyLabel: 'Friends Only',
    safetyFriendsOnlyDesc: 'Only your friends can see your profile',
    safetyPrivateLabel: 'Private',
    safetyPrivateDesc: 'No one can discover your profile',

    // Room (extra 2)
    roomChatTab: 'Chat 💬',
    roomWhosHereTab: "Who's Here 👥",
    roomPhotoWallTab: 'Photo Wall 📸',
    roomVibeTab: 'Vibe ✨',
    roomSaySomething: 'Say something...',
    roomBeFirstSay: 'Be the first to say something!',
    roomHereNow: 'here now',
    roomIAmHere: "I'm Here!",
    roomNoOneCheckedIn: 'No one checked in yet',
    roomBeFirst: 'Be the first!',
    roomPhotoComingSoon: 'Photo sharing coming soon',
    roomAddFirstPhoto: 'Add the first photo!',
    roomNoActivePoll: 'No active poll right now',
    roomPopularVibes: 'Popular Vibes Here',
    roomShareMomentTitle: 'Share a Moment',
    roomWhatHappening: "What's happening right now?",
    roomPostMoment: 'Post Moment',
    roomRecentMoments: 'Recent Moments',
    roomSubmitVote: 'Submit Vote',
    roomCheckedIn: "You're checked in!",
    roomCheckinFailed: 'Check-in failed',
    roomFailedSend: 'Failed to send',
    roomVoteSuccess: 'Vote submitted!',
    roomVoteFailed: 'Failed to vote',
    roomMomentFailed: 'Failed to post',
    roomJustNow: 'Just now',
    roomMinAgo: 'm ago',
    roomHourAgo: 'h ago',
    roomDayAgo: 'd ago',
    roomOutNow: 'Out Now',
    roomGoingOutSoon: 'Going Out Soon',
    roomStayingIn: 'Staying In',
    roomPollLabel: 'POLL',
    roomTheRoomDefault: 'The Room',

    // Safe Arrival (extra 2)
    safeArrivalFriendsSection: 'Safety Friends',
    safeArrivalAddBtn: 'Add',
    safeArrivalAddFriendDialog: 'Add Safety Friend',
    safeArrivalSearchHint: 'Search by name...',
    safeArrivalWillNotify: 'Will be notified',
    safeArrivalRecentSection: 'Recent Safe Arrivals',
    safeArrivalNoRecent: 'No safe arrivals recorded yet',
    safeArrivalArrivedSafe: 'Arrived safe',
    safeArrivalEmergencySection: 'Emergency',
    safeArrivalCall911: 'Call 911',
    safeArrivalCall112: 'Call 112',
    safeArrivalIAmHome: "I'm Home Safe!",
    safeArrivalRecordingState: 'Recording...',
    safeArrivalRecordedTitle: 'Safe Arrival Recorded!',
    safeArrivalNotifyMsg: 'Your safety friends have been notified.',
    safeArrivalGreat: 'Great!',
    safeArrivalFailedRecord: 'Failed to record safe arrival. Try again.',
    safeArrivalFriendAdded: 'Safety friend added!',
    safeArrivalAddFriendPrompt: 'Add friends to notify when you arrive safe',
    safeArrivalLetFriendsKnow:
        'Let your friends know when you get home safe.',

    // Night Recap (extra 2)
    recapNightTitle: "Last Night's Recap",
    recapActivitiesCount: 'activities recorded',
    recapStartGoingOut: 'Start by going out 🍻',
    recapVenueCheckin: 'Venue Check-in',
    recapMessageSent: 'Message Sent',
    recapSwarmJoined: 'Joined Swarm',
    recapGiftSent: 'Gift Sent',
    recapActivity: 'Activity',
    recapSentMessage: 'Sent a message',
    recapVenueDefault: 'A venue',
    recapSwarmDefault: 'A swarm',
    recapGiftDefault: 'A gift',
    recapMessagesLabel: 'Messages',
    recapSwarmsLabel: 'Swarms',
  };
}
