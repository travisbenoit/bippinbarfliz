// Central translation-key registry.
// Keys follow the pattern  <area>.<name>  (all lowercase, dot-separated).
// englishFallback is the source-of-truth for English text; it also acts as the
// ultimate fallback when Supabase has no row for the active language.
class AppStrings {
  AppStrings._();

  // ── Common ──────────────────────────────────────────────────────────────────
  static const ok             = 'common.ok';
  static const cancel         = 'common.cancel';
  static const save           = 'common.save';
  static const close          = 'common.close';
  static const done           = 'common.done';
  static const next           = 'common.next';
  static const skip           = 'common.skip';
  static const back           = 'common.back';
  static const confirm        = 'common.confirm';
  static const error          = 'common.error';
  static const loading        = 'common.loading';
  static const retry          = 'common.retry';
  static const send           = 'common.send';
  static const search         = 'common.search';
  static const add            = 'common.add';
  static const remove         = 'common.remove';
  static const share          = 'common.share';
  static const block          = 'common.block';
  static const unblock        = 'common.unblock';
  static const report         = 'common.report';
  static const viewAll        = 'common.view_all';
  static const unknownUser    = 'common.unknown_user';
  static const unknown        = 'common.unknown';
  static const optional       = 'common.optional';
  static const appName        = 'common.app_name';
  static const version        = 'common.version';

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const signInTitle         = 'auth.sign_in_title';
  static const signInSubtitle      = 'auth.sign_in_subtitle';
  static const signInButton        = 'auth.sign_in_button';
  static const signInForgot        = 'auth.sign_in_forgot';
  static const signInNoAccount     = 'auth.sign_in_no_account';
  static const signInGoSignUp      = 'auth.sign_in_go_sign_up';
  static const signUpTitle         = 'auth.sign_up_title';
  static const signUpSubtitle      = 'auth.sign_up_subtitle';
  static const signUpButton        = 'auth.sign_up_button';
  static const signUpHaveAccount   = 'auth.sign_up_have_account';
  static const signUpGoSignIn      = 'auth.sign_up_go_sign_in';
  static const fieldEmail          = 'auth.field_email';
  static const fieldPassword       = 'auth.field_password';
  static const fieldName           = 'auth.field_name';
  static const fieldConfirmPass    = 'auth.field_confirm_password';
  static const signOut             = 'auth.sign_out';
  static const signOutTitle        = 'auth.sign_out_title';
  static const signOutConfirm      = 'auth.sign_out_confirm';

  // ── Navigation (bottom bar + more sheet) ────────────────────────────────────
  static const navHome             = 'nav.home';
  static const navMap              = 'nav.map';
  static const navMessages         = 'nav.messages';
  static const navProfile          = 'nav.profile';
  static const navMore             = 'nav.more';
  static const moreFriends         = 'nav.more_friends';
  static const moreHistory         = 'nav.more_history';
  static const morePayments        = 'nav.more_payments';
  static const moreLeaderboard     = 'nav.more_leaderboard';
  static const moreNightRecap      = 'nav.more_night_recap';
  static const moreNotifications   = 'nav.more_notifications';

  // ── Onboarding ──────────────────────────────────────────────────────────────
  static const onboardingSkip      = 'onboarding.skip';
  static const onboardingNext      = 'onboarding.next';
  static const onboardingStart     = 'onboarding.get_started';

  // ── Permissions ─────────────────────────────────────────────────────────────
  static const permissionsTitle    = 'permissions.title';
  static const permissionsSubtitle = 'permissions.subtitle';
  static const permissionsLocation = 'permissions.location';
  static const permissionsLocSubtitle = 'permissions.location_subtitle';
  static const permissionsNotifs   = 'permissions.notifications';
  static const permissionsNotifsSubtitle = 'permissions.notifications_subtitle';
  static const permissionsAllow    = 'permissions.allow';
  static const permissionsSkip     = 'permissions.skip';
  static const permissionsContinue = 'permissions.continue';

  // ── Home ────────────────────────────────────────────────────────────────────
  static const homeTitle           = 'home.title';
  static const homeGoodEvening     = 'home.good_evening';
  static const homeTonightStatus   = 'home.tonight_status';
  static const homeGoingOut        = 'home.going_out';
  static const homeMaybe           = 'home.maybe';
  static const homeStayingIn       = 'home.staying_in';
  static const homeOutNow          = 'home.out_now';
  static const homePopularVenues   = 'home.popular_venues';
  static const homeActiveSwarms    = 'home.active_swarms';
  static const homeQuickActions    = 'home.quick_actions';
  static const homeNearbyPeople    = 'home.nearby_people';
  static const homeSceneTonight    = 'home.scene_tonight';
  static const homeDdTonight       = 'home.dd_tonight';
  static const homeSafeArrival     = 'home.safe_arrival';
  static const homeCheckins        = 'home.checkins';
  static const homeFriends         = 'home.friends';
  static const homeSwarms          = 'home.swarms';
  static const homeLevel           = 'home.level';
  static const homeXp              = 'home.xp';
  static const homeStreak          = 'home.streak';
  static const homeNoVenues        = 'home.no_venues';
  static const homeNoSwarms        = 'home.no_swarms';
  static const homeNoNearby        = 'home.no_nearby';
  static const homePeopleOut       = 'home.people_out';
  static const homeCheckIn         = 'home.check_in';
  static const homeSendGift        = 'home.send_gift';
  static const homeMapView         = 'home.map_view';
  static const homeCreateSwarm     = 'home.create_swarm';

  // ── Map ─────────────────────────────────────────────────────────────────────
  static const mapTitle            = 'map.title';
  static const mapVenues           = 'map.venues';
  static const mapPeople           = 'map.people';
  static const mapFilterAll        = 'map.filter_all';
  static const mapFilterBars       = 'map.filter_bars';
  static const mapFilterClubs      = 'map.filter_clubs';
  static const mapFilterRestaurants = 'map.filter_restaurants';
  static const mapNoVenues         = 'map.no_venues';
  static const mapOpenInMaps       = 'map.open_in_maps';
  static const mapGetDirections    = 'map.get_directions';
  static const mapCheckIn          = 'map.check_in';

  // ── Messages ────────────────────────────────────────────────────────────────
  static const messagesTitle       = 'messages.title';
  static const messagesEmpty       = 'messages.empty';
  static const messagesEmptySub    = 'messages.empty_subtitle';
  static const messagesHint        = 'messages.hint';
  static const messagesYou         = 'messages.you';
  static const chatTitle           = 'messages.chat_title';
  static const chatInputHint       = 'messages.chat_input_hint';
  static const chatSend            = 'messages.chat_send';

  // ── Profile ─────────────────────────────────────────────────────────────────
  static const profileTitle        = 'profile.title';
  static const profileEdit         = 'profile.edit';
  static const profileFollowers    = 'profile.followers';
  static const profileFollowing    = 'profile.following';
  static const profileFriends      = 'profile.friends';
  static const profileBio          = 'profile.bio';
  static const profileInterests    = 'profile.interests';
  static const profileCheckins     = 'profile.checkins';
  static const profileXp           = 'profile.xp';
  static const profileLevel        = 'profile.level';
  static const profileAddFriend    = 'profile.add_friend';
  static const profileSendGift     = 'profile.send_gift';
  static const profileSendMessage  = 'profile.send_message';
  static const profileBlockUser    = 'profile.block_user';
  static const profileReportUser   = 'profile.report_user';

  // ── Friends ─────────────────────────────────────────────────────────────────
  static const friendsTitle        = 'friends.title';
  static const friendsTabFriends   = 'friends.tab_friends';
  static const friendsTabRequests  = 'friends.tab_requests';
  static const friendsTabFind      = 'friends.tab_find';
  static const friendsEmpty        = 'friends.empty';
  static const friendsEmptySub     = 'friends.empty_subtitle';
  static const friendsNoRequests   = 'friends.no_requests';
  static const friendsNoRequestsSub = 'friends.no_requests_subtitle';
  static const friendsSearchHint   = 'friends.search_hint';
  static const friendsAccept       = 'friends.accept';
  static const friendsDecline      = 'friends.decline';
  static const friendsPending      = 'friends.pending';
  static const friendsRemove       = 'friends.remove_friend';
  static const friendsAddFriend    = 'friends.add_friend';
  static const friendsRequestSent  = 'friends.request_sent';
  static const friendsAlready      = 'friends.already_friends';
  static const friendsMutualCount  = 'friends.mutual_count';
  static const friendsFindPeople   = 'friends.find_people';

  // ── Notifications ───────────────────────────────────────────────────────────
  static const notificationsTitle  = 'notifications.title';
  static const notificationsEmpty  = 'notifications.empty';
  static const notificationsMarkAll = 'notifications.mark_all_read';
  static const notificationsToday  = 'notifications.today';
  static const notificationsEarlier = 'notifications.earlier';

  // ── Leaderboard ─────────────────────────────────────────────────────────────
  static const leaderboardTitle    = 'leaderboard.title';
  static const leaderboardTab      = 'leaderboard.tab_leaderboard';
  static const challengesTab       = 'leaderboard.tab_challenges';
  static const leaderboardMyStats  = 'leaderboard.my_stats';
  static const leaderboardRank     = 'leaderboard.rank';
  static const leaderboardXp       = 'leaderboard.xp';
  static const leaderboardStreak   = 'leaderboard.streak';
  static const leaderboardCheckins = 'leaderboard.checkins';
  static const leaderboardEmpty    = 'leaderboard.empty';
  static const challengesEmpty     = 'leaderboard.challenges_empty';
  static const challengeCompleted  = 'leaderboard.challenge_completed';
  static const challengeInProgress = 'leaderboard.challenge_in_progress';
  static const challengeLocked     = 'leaderboard.challenge_locked';
  static const challengeXpReward   = 'leaderboard.challenge_xp_reward';

  // ── Settings ────────────────────────────────────────────────────────────────
  static const settingsTitle       = 'settings.title';
  static const settingsAccount     = 'settings.section_account';
  static const settingsSocial      = 'settings.section_social';
  static const settingsPrivacy     = 'settings.section_privacy';
  static const settingsPayments    = 'settings.section_payments';
  static const settingsMore        = 'settings.section_more';
  static const settingsEditProfile = 'settings.edit_profile';
  static const settingsEditProfileSub = 'settings.edit_profile_subtitle';
  static const settingsAppearance  = 'settings.appearance';
  static const settingsDarkOn      = 'settings.dark_mode_on';
  static const settingsLightOn     = 'settings.light_mode_on';
  static const settingsLanguage    = 'settings.language';
  static const settingsLanguageSub = 'settings.language_subtitle';
  static const settingsFriends     = 'settings.friends';
  static const settingsFriendsSub  = 'settings.friends_subtitle';
  static const settingsNotifications = 'settings.notifications';
  static const settingsNotifsSub   = 'settings.notifications_subtitle';
  static const settingsSafety      = 'settings.safety';
  static const settingsSafetySub   = 'settings.safety_subtitle';
  static const settingsBlocked     = 'settings.blocked_users';
  static const settingsBlockedSub  = 'settings.blocked_users_subtitle';
  static const settingsPremium     = 'settings.premium';
  static const settingsPremiumSub  = 'settings.premium_subtitle';
  static const settingsPaymentsTitle = 'settings.payments';
  static const settingsPaymentsSub = 'settings.payments_subtitle';
  static const settingsMyGifts     = 'settings.my_gifts';
  static const settingsMyGiftsSub  = 'settings.my_gifts_subtitle';
  static const settingsHistory     = 'settings.history';
  static const settingsHistorySub  = 'settings.history_subtitle';
  static const settingsLeaderboard = 'settings.leaderboard';
  static const settingsLeaderboardSub = 'settings.leaderboard_subtitle';
  static const settingsHelp        = 'settings.help';
  static const settingsHelpSub     = 'settings.help_subtitle';
  static const settingsPrivacyPolicy = 'settings.privacy_policy';
  static const settingsPrivacySub  = 'settings.privacy_policy_subtitle';
  static const settingsTerms       = 'settings.terms';

  // ── Language settings ───────────────────────────────────────────────────────
  static const languageTitle       = 'language.title';
  static const languageSelect      = 'language.select';

  // ── Blocked users ───────────────────────────────────────────────────────────
  static const blockedTitle        = 'blocked.title';
  static const blockedEmpty        = 'blocked.empty';
  static const blockedEmptySub     = 'blocked.empty_subtitle';
  static const blockedOn           = 'blocked.blocked_on';
  static const blockedUnblock      = 'blocked.unblock';
  static const blockedLoadError    = 'blocked.load_error';
  static const blockedUnblockOk    = 'blocked.unblock_success';
  static const blockedUnblockError = 'blocked.unblock_error';

  // ── Send Gift ───────────────────────────────────────────────────────────────
  static const giftTitle           = 'gift.title';
  static const giftTitleTo         = 'gift.title_to';
  static const giftChooseDrink     = 'gift.choose_drink';
  static const giftAmount          = 'gift.amount';
  static const giftMessageHint     = 'gift.message_hint';
  static const giftSendButton      = 'gift.send_button';
  static const giftSentSuccess     = 'gift.sent_success';
  static const giftSendError       = 'gift.send_error';
  static const giftDrinkBeer       = 'gift.drink_beer';
  static const giftDrinkWine       = 'gift.drink_wine';
  static const giftDrinkCocktail   = 'gift.drink_cocktail';
  static const giftDrinkShot       = 'gift.drink_shot';
  static const giftDrinkCustom     = 'gift.drink_custom';

  // ── Gifts received ──────────────────────────────────────────────────────────
  static const giftsTitle          = 'gifts.title';
  static const giftsEmpty          = 'gifts.empty';
  static const giftsEmptySub       = 'gifts.empty_subtitle';
  static const giftsFrom           = 'gifts.from';
  static const giftsPending        = 'gifts.pending';
  static const giftsAccepted       = 'gifts.accepted';

  // ── History ─────────────────────────────────────────────────────────────────
  static const historyTitle        = 'history.title';
  static const historyTabActivity  = 'history.tab_activity';
  static const historyTabVisits    = 'history.tab_visits';
  static const historyEmpty        = 'history.empty';
  static const historyEmptySub     = 'history.empty_subtitle';

  // ── Payments ────────────────────────────────────────────────────────────────
  static const paymentsTitle       = 'payments.title';
  static const paymentsTabOverview = 'payments.tab_overview';
  static const paymentsTabSend     = 'payments.tab_send';
  static const paymentsTabHistory  = 'payments.tab_history';
  static const paymentsBalance     = 'payments.balance';
  static const paymentsLushCoins   = 'payments.lush_coins';
  static const paymentsSendMoney   = 'payments.send_money';
  static const paymentsEmpty       = 'payments.empty';

  // ── Premium ─────────────────────────────────────────────────────────────────
  static const premiumTitle        = 'premium.title';
  static const premiumSubtitle     = 'premium.subtitle';
  static const premiumMonthly      = 'premium.monthly';
  static const premiumYearly       = 'premium.yearly';
  static const premiumGetPremium   = 'premium.get_premium';
  static const premiumAlreadySub   = 'premium.already_subscribed';
  static const premiumFeaturesTitle = 'premium.features_title';

  // ── Discover ────────────────────────────────────────────────────────────────
  static const discoverTitle       = 'discover.title';
  static const discoverNoResults   = 'discover.no_results';
  static const discoverLike        = 'discover.like';
  static const discoverSkip        = 'discover.skip';
  static const discoverMatch       = 'discover.match';

  // ── People Nearby ───────────────────────────────────────────────────────────
  static const peopleTitle         = 'people.title';
  static const peopleEmpty         = 'people.empty';
  static const peopleEmptySub      = 'people.empty_subtitle';
  static const peopleFilterAll     = 'people.filter_all';
  static const peopleFilterOut     = 'people.filter_out_now';
  static const peopleFilterGoing   = 'people.filter_going_out';
  static const peopleSearchHint    = 'people.search_hint';
  static const peopleNearby        = 'people.nearby_count';
  static const peopleAddFriend     = 'people.add_friend';

  // ── Swarms ──────────────────────────────────────────────────────────────────
  static const swarmsTitle         = 'swarms.title';
  static const swarmsCreate        = 'swarms.create';
  static const swarmsJoin          = 'swarms.join';
  static const swarmsEmpty         = 'swarms.empty';
  static const swarmsEmptySub      = 'swarms.empty_subtitle';
  static const swarmsMembers       = 'swarms.members';
  static const swarmsLeave         = 'swarms.leave';

  // ── Safety ──────────────────────────────────────────────────────────────────
  static const safetyTitle         = 'safety.title';
  static const safetyGhostMode     = 'safety.ghost_mode';
  static const safetyGhostSub      = 'safety.ghost_mode_subtitle';
  static const safetySafeArrival   = 'safety.safe_arrival';
  static const safetySafeArrivalSub = 'safety.safe_arrival_subtitle';
  static const safetyEmergency     = 'safety.emergency_contacts';
  static const safetyEmergencySub  = 'safety.emergency_contacts_subtitle';
  static const safetyBlockedUsers  = 'safety.blocked_users';

  // ── Notifications settings ──────────────────────────────────────────────────
  static const notifSettingsTitle  = 'notif_settings.title';
  static const notifSettingsSaved  = 'notif_settings.saved';

  // ── Edit profile ────────────────────────────────────────────────────────────
  static const editProfileTitle    = 'edit_profile.title';
  static const editProfileSave     = 'edit_profile.save';
  static const editProfileName     = 'edit_profile.name';
  static const editProfileBio      = 'edit_profile.bio';
  static const editProfileDob      = 'edit_profile.dob';
  static const editProfileInterests = 'edit_profile.interests';
  static const editProfilePhoto    = 'edit_profile.change_photo';

  // ── Night Recap ─────────────────────────────────────────────────────────────
  static const recapTitle          = 'recap.title';
  static const recapSubtitle       = 'recap.subtitle';
  static const recapVenues         = 'recap.venues_visited';
  static const recapPeople         = 'recap.people_met';
  static const recapXpEarned       = 'recap.xp_earned';

  // ── The Room ────────────────────────────────────────────────────────────────
  static const roomTitle           = 'room.title';
  static const roomTabChat         = 'room.tab_chat';
  static const roomTabPeople       = 'room.tab_people';
  static const roomTabPhotos       = 'room.tab_photos';
  static const roomTabMoments      = 'room.tab_moments';
  static const roomInputHint       = 'room.input_hint';

  // ── Music ───────────────────────────────────────────────────────────────────
  static const musicTitle          = 'music.title';
  static const musicSearchHint     = 'music.search_hint';
  static const musicShare          = 'music.share';
  static const musicShared         = 'music.shared';
  static const musicEmpty          = 'music.empty';

  // ── Profile setup ───────────────────────────────────────────────────────────
  static const profileSetupTitle   = 'profile_setup.title';
  static const profileSetupSubtitle = 'profile_setup.subtitle';
  static const profileSetupContinue = 'profile_setup.continue';

  // ── Safe Arrival ────────────────────────────────────────────────────────────
  static const safeArrivalTitle    = 'safe_arrival.title';
  static const safeArrivalChecked  = 'safe_arrival.checked_in';
  static const safeArrivalNotify   = 'safe_arrival.notify_contacts';

  // ── Report ──────────────────────────────────────────────────────────────────
  static const reportTitle         = 'report.title';
  static const reportSubmit        = 'report.submit';
  static const reportSuccess       = 'report.success';
  static const reportReasonSpam    = 'report.reason_spam';
  static const reportReasonHarassment = 'report.reason_harassment';
  static const reportReasonHate    = 'report.reason_hate_speech';
  static const reportReasonSexual  = 'report.reason_sexual_content';
  static const reportReasonViolence = 'report.reason_violence';
  static const reportReasonUnderage = 'report.reason_underage';
  static const reportReasonImpersonation = 'report.reason_impersonation';
  static const reportReasonSafety  = 'report.reason_safety';
  static const reportReasonOther   = 'report.reason_other';

  // ── First run tour ──────────────────────────────────────────────────────────
  static const tourStep1Title      = 'tour.step1_title';
  static const tourStep1Body       = 'tour.step1_body';
  static const tourStep2Title      = 'tour.step2_title';
  static const tourStep2Body       = 'tour.step2_body';
  static const tourStep3Title      = 'tour.step3_title';
  static const tourStep3Body       = 'tour.step3_body';
  static const tourStep4Title      = 'tour.step4_title';
  static const tourStep4Body       = 'tour.step4_body';
  static const tourLetsGo         = 'tour.lets_go';

  // ── Dialogs ─────────────────────────────────────────────────────────────────
  static const helpTitle           = 'help.title';
  static const privacyTitle        = 'privacy.title';
  static const termsTitle          = 'terms.title';

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // English fallback — used when Supabase has no translation for the active lang
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const Map<String, String> englishFallback = {
    // Common
    ok:             'OK',
    cancel:         'Cancel',
    save:           'Save',
    close:          'Close',
    done:           'Done',
    next:           'Next',
    skip:           'Skip',
    back:           'Back',
    confirm:        'Confirm',
    error:          'Error',
    loading:        'Loading…',
    retry:          'Retry',
    send:           'Send',
    search:         'Search',
    add:            'Add',
    remove:         'Remove',
    share:          'Share',
    block:          'Block',
    unblock:        'Unblock',
    report:         'Report',
    viewAll:        'View All',
    unknownUser:    'Unknown user',
    unknown:        'Unknown',
    optional:       'optional',
    appName:        'Barfliz',
    version:        'Barfliz v1.0.0',

    // Auth
    signInTitle:        'Welcome back',
    signInSubtitle:     'Sign in to your account',
    signInButton:       'Sign In',
    signInForgot:       'Forgot password?',
    signInNoAccount:    "Don't have an account?",
    signInGoSignUp:     'Sign Up',
    signUpTitle:        'Create account',
    signUpSubtitle:     'Join Barfliz tonight',
    signUpButton:       'Create Account',
    signUpHaveAccount:  'Already have an account?',
    signUpGoSignIn:     'Sign In',
    fieldEmail:         'Email',
    fieldPassword:      'Password',
    fieldName:          'Full name',
    fieldConfirmPass:   'Confirm password',
    signOut:            'Sign Out',
    signOutTitle:       'Sign Out',
    signOutConfirm:     'Are you sure you want to sign out?',

    // Navigation
    navHome:            'Home',
    navMap:             'Map',
    navMessages:        'Messages',
    navProfile:         'Profile',
    navMore:            'More',
    moreFriends:        'Friends',
    moreHistory:        'History',
    morePayments:       'Payments',
    moreLeaderboard:    'Leaderboard',
    moreNightRecap:     'Night Recap',
    moreNotifications:  'Notifications',

    // Onboarding
    onboardingSkip:     'Skip',
    onboardingNext:     'Next',
    onboardingStart:    "Let's Go",

    // Permissions
    permissionsTitle:        'Permissions',
    permissionsSubtitle:     'Allow the following to get the most out of Barfliz',
    permissionsLocation:     'Location',
    permissionsLocSubtitle:  'Find venues and people near you',
    permissionsNotifs:       'Notifications',
    permissionsNotifsSubtitle: 'Get updates on friends and events',
    permissionsAllow:        'Allow',
    permissionsSkip:         'Skip for now',
    permissionsContinue:     'Continue',

    // Home
    homeTitle:          'Home',
    homeGoodEvening:    'Good evening',
    homeTonightStatus:  "Tonight's Status",
    homeGoingOut:       'Going Out',
    homeMaybe:          'Maybe',
    homeStayingIn:      'Staying In',
    homeOutNow:         'Out Now',
    homePopularVenues:  'Popular Venues',
    homeActiveSwarms:   'Active Swarms',
    homeQuickActions:   'Quick Actions',
    homeNearbyPeople:   'Nearby People',
    homeSceneTonight:   "Tonight's Scene",
    homeDdTonight:      'DD Tonight',
    homeSafeArrival:    'Safe Arrival',
    homeCheckins:       'Check-ins',
    homeFriends:        'Friends',
    homeSwarms:         'Swarms',
    homeLevel:          'Level',
    homeXp:             'XP',
    homeStreak:         'Streak',
    homeNoVenues:       'No venues nearby',
    homeNoSwarms:       'No active swarms',
    homeNoNearby:       'No one nearby right now',
    homePeopleOut:      'people out tonight',
    homeCheckIn:        'Check In',
    homeSendGift:       'Send Gift',
    homeMapView:        'Map View',
    homeCreateSwarm:    'Create Swarm',

    // Map
    mapTitle:           'Map',
    mapVenues:          'Venues',
    mapPeople:          'People',
    mapFilterAll:       'All',
    mapFilterBars:      'Bars',
    mapFilterClubs:     'Clubs',
    mapFilterRestaurants: 'Restaurants',
    mapNoVenues:        'No venues in this area',
    mapOpenInMaps:      'Open in Maps',
    mapGetDirections:   'Get Directions',
    mapCheckIn:         'Check In',

    // Messages
    messagesTitle:      'Messages',
    messagesEmpty:      'No conversations yet',
    messagesEmptySub:   'Start chatting with friends to see messages here',
    messagesHint:       'Type a message…',
    messagesYou:        'You',
    chatTitle:          'Chat',
    chatInputHint:      'Message…',
    chatSend:           'Send',

    // Profile
    profileTitle:       'Profile',
    profileEdit:        'Edit Profile',
    profileFollowers:   'Followers',
    profileFollowing:   'Following',
    profileFriends:     'Friends',
    profileBio:         'Bio',
    profileInterests:   'Interests',
    profileCheckins:    'Check-ins',
    profileXp:          'XP',
    profileLevel:       'Level',
    profileAddFriend:   'Add Friend',
    profileSendGift:    'Send Gift',
    profileSendMessage: 'Message',
    profileBlockUser:   'Block User',
    profileReportUser:  'Report User',

    // Friends
    friendsTitle:       'Friends',
    friendsTabFriends:  'Friends',
    friendsTabRequests: 'Requests',
    friendsTabFind:     'Find',
    friendsEmpty:       'No friends yet',
    friendsEmptySub:    'Use Find Friends to connect with people going out tonight',
    friendsNoRequests:  'No pending requests',
    friendsNoRequestsSub: 'Friend requests will appear here',
    friendsSearchHint:  'Search people…',
    friendsAccept:      'Accept',
    friendsDecline:     'Decline',
    friendsPending:     'Pending',
    friendsRemove:      'Remove Friend',
    friendsAddFriend:   'Add Friend',
    friendsRequestSent: 'Request Sent',
    friendsAlready:     'Friends',
    friendsMutualCount: 'mutual friends',
    friendsFindPeople:  'Find People',

    // Notifications
    notificationsTitle:  'Notifications',
    notificationsEmpty:  'No notifications yet',
    notificationsMarkAll: 'Mark all as read',
    notificationsToday:  'Today',
    notificationsEarlier: 'Earlier',

    // Leaderboard
    leaderboardTitle:   'Leaderboard & XP',
    leaderboardTab:     'Leaderboard',
    challengesTab:      'Challenges',
    leaderboardMyStats: 'My Stats',
    leaderboardRank:    'Rank',
    leaderboardXp:      'XP',
    leaderboardStreak:  'Streak',
    leaderboardCheckins: 'Check-ins',
    leaderboardEmpty:   'No data yet',
    challengesEmpty:    'No challenges available',
    challengeCompleted: 'Completed',
    challengeInProgress: 'In Progress',
    challengeLocked:    'Locked',
    challengeXpReward:  'XP reward',

    // Settings
    settingsTitle:          'Settings',
    settingsAccount:        'Account',
    settingsSocial:         'Social',
    settingsPrivacy:        'Privacy & Safety',
    settingsPayments:       'Payments & Premium',
    settingsMore:           'More',
    settingsEditProfile:    'Edit Profile',
    settingsEditProfileSub: 'Update your name, bio, photos',
    settingsAppearance:     'Appearance',
    settingsDarkOn:         'Dark mode on',
    settingsLightOn:        'Light mode on',
    settingsLanguage:       'Language',
    settingsLanguageSub:    'Change app language',
    settingsFriends:        'Friends',
    settingsFriendsSub:     'Manage your friend list',
    settingsNotifications:  'Notifications',
    settingsNotifsSub:      'Manage notification preferences',
    settingsSafety:         'Safety & Security',
    settingsSafetySub:      'Ghost mode, safe arrival, emergency contacts',
    settingsBlocked:        'Blocked Users',
    settingsBlockedSub:     'Manage users you have blocked',
    settingsPremium:        'Go Premium',
    settingsPremiumSub:     'Unlock all features',
    settingsPaymentsTitle:  'Payments',
    settingsPaymentsSub:    'Send money, LushCoin balance',
    settingsMyGifts:        'My Gifts',
    settingsMyGiftsSub:     'View received gifts',
    settingsHistory:        'Activity History',
    settingsHistorySub:     'Your nightlife history',
    settingsLeaderboard:    'Leaderboard & XP',
    settingsLeaderboardSub: 'Your rank and achievements',
    settingsHelp:           'Help Center',
    settingsHelpSub:        'FAQs and support',
    settingsPrivacyPolicy:  'Privacy Policy',
    settingsPrivacySub:     'How we handle your data',
    settingsTerms:          'Terms of Service',

    // Language
    languageTitle:      'Language',
    languageSelect:     'Select Language',

    // Blocked users
    blockedTitle:       'Blocked Users',
    blockedEmpty:       'No blocked users',
    blockedEmptySub:    "Users you block won't be able to see your profile or message you.",
    blockedOn:          'Blocked',
    blockedUnblock:     'Unblock',
    blockedLoadError:   'Could not load blocked users.',
    blockedUnblockOk:   'Unblocked.',
    blockedUnblockError: 'Could not unblock. Please try again.',

    // Send gift
    giftTitle:          'Send a Gift',
    giftTitleTo:        'Send Gift to',
    giftChooseDrink:    'Choose a drink',
    giftAmount:         'Amount',
    giftMessageHint:    'Add a message (optional)',
    giftSendButton:     'Send Gift',
    giftSentSuccess:    'Gift sent!',
    giftSendError:      'Failed to send gift',
    giftDrinkBeer:      'Beer',
    giftDrinkWine:      'Wine',
    giftDrinkCocktail:  'Cocktail',
    giftDrinkShot:      'Shot',
    giftDrinkCustom:    'Custom',

    // Gifts received
    giftsTitle:         'My Gifts',
    giftsEmpty:         'No gifts yet',
    giftsEmptySub:      'Gifts from friends will appear here',
    giftsFrom:          'From',
    giftsPending:       'Pending',
    giftsAccepted:      'Accepted',

    // History
    historyTitle:       'Activity History',
    historyTabActivity: 'Activity',
    historyTabVisits:   'Visits',
    historyEmpty:       'No activity yet',
    historyEmptySub:    'Check in at venues to start your history',

    // Payments
    paymentsTitle:      'Payments',
    paymentsTabOverview: 'Overview',
    paymentsTabSend:    'Send',
    paymentsTabHistory: 'History',
    paymentsBalance:    'Balance',
    paymentsLushCoins:  'LushCoin Balance',
    paymentsSendMoney:  'Send Money',
    paymentsEmpty:      'No transactions yet',

    // Premium
    premiumTitle:       'Go Premium',
    premiumSubtitle:    'Unlock the full Barfliz experience',
    premiumMonthly:     'Monthly',
    premiumYearly:      'Yearly',
    premiumGetPremium:  'Get Premium',
    premiumAlreadySub:  "You're already subscribed!",
    premiumFeaturesTitle: 'Premium Features',

    // Discover
    discoverTitle:      'Discover',
    discoverNoResults:  'No more people to show',
    discoverLike:       'Like',
    discoverSkip:       'Skip',
    discoverMatch:      "It's a Match!",

    // People Nearby
    peopleTitle:        'People Nearby',
    peopleEmpty:        'No one nearby right now',
    peopleEmptySub:     'Check back later when more people are going out',
    peopleFilterAll:    'All',
    peopleFilterOut:    'Out Now',
    peopleFilterGoing:  'Going Out',
    peopleSearchHint:   'Search people…',
    peopleNearby:       'nearby',
    peopleAddFriend:    'Add Friend',

    // Swarms
    swarmsTitle:        'Swarms',
    swarmsCreate:       'Create Swarm',
    swarmsJoin:         'Join',
    swarmsEmpty:        'No active swarms',
    swarmsEmptySub:     'Create a swarm to invite friends to hang out',
    swarmsMembers:      'members',
    swarmsLeave:        'Leave Swarm',

    // Safety
    safetyTitle:        'Safety & Security',
    safetyGhostMode:    'Ghost Mode',
    safetyGhostSub:     'Hide your location and profile from others',
    safetySafeArrival:  'Safe Arrival',
    safetySafeArrivalSub: 'Let contacts know you arrived safely',
    safetyEmergency:    'Emergency Contacts',
    safetyEmergencySub: 'People to notify in an emergency',
    safetyBlockedUsers: 'Blocked Users',

    // Notifications settings
    notifSettingsTitle: 'Notification Settings',
    notifSettingsSaved: 'Settings saved',

    // Edit profile
    editProfileTitle:   'Edit Profile',
    editProfileSave:    'Save',
    editProfileName:    'Name',
    editProfileBio:     'Bio',
    editProfileDob:     'Date of Birth',
    editProfileInterests: 'Interests',
    editProfilePhoto:   'Change Photo',

    // Night Recap
    recapTitle:         'Night Recap',
    recapSubtitle:      "Here's how your night went",
    recapVenues:        'Venues Visited',
    recapPeople:        'People Met',
    recapXpEarned:      'XP Earned',

    // Room
    roomTitle:          'The Room',
    roomTabChat:        'Chat',
    roomTabPeople:      'People',
    roomTabPhotos:      'Photos',
    roomTabMoments:     'Moments',
    roomInputHint:      'Message the room…',

    // Music
    musicTitle:         'Music',
    musicSearchHint:    'Search songs, artists…',
    musicShare:         'Share',
    musicShared:        'Shared!',
    musicEmpty:         'No music shared yet',

    // Profile setup
    profileSetupTitle:    'Set Up Your Profile',
    profileSetupSubtitle: 'Tell us a bit about yourself',
    profileSetupContinue: 'Continue',

    // Safe Arrival
    safeArrivalTitle:   'Safe Arrival',
    safeArrivalChecked: 'Checked In Safely',
    safeArrivalNotify:  'Notify my contacts',

    // Report
    reportTitle:        'Report',
    reportSubmit:       'Submit Report',
    reportSuccess:      'Report submitted. Thank you.',
    reportReasonSpam:   'Spam',
    reportReasonHarassment: 'Harassment',
    reportReasonHate:   'Hate Speech',
    reportReasonSexual: 'Sexual Content',
    reportReasonViolence: 'Violence',
    reportReasonUnderage: 'Underage User',
    reportReasonImpersonation: 'Impersonation',
    reportReasonSafety: 'Safety Concern',
    reportReasonOther:  'Other',

    // First run tour
    tourStep1Title:     "Tonight's Status",
    tourStep1Body:      'Let friends know if you\'re going out tonight',
    tourStep2Title:     'Live Map',
    tourStep2Body:      'See venues and friends near you in real time',
    tourStep3Title:     'Swarms',
    tourStep3Body:      'Create or join group hangouts at your favourite spots',
    tourStep4Title:     'Friends & Chat',
    tourStep4Body:      'Connect with friends and keep the night going',
    tourLetsGo:         "Let's Go!",

    // Dialogs
    helpTitle:          'Help Center',
    privacyTitle:       'Privacy Policy',
    termsTitle:         'Terms of Service',
  };
}
