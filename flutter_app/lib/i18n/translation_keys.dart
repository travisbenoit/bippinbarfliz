/// Shared translation keys for the Flutter app
/// Keys must match exactly with web implementation for consistency
class TranslationKeys {
  // Navigation
  static const String navExplore = 'nav.explore';
  static const String navSwarms = 'nav.swarms';
  static const String navMessages = 'nav.messages';
  static const String navGifts = 'nav.gifts';
  static const String navPay = 'nav.pay';
  static const String navProfile = 'nav.profile';
  static const String navSettings = 'nav.settings';

  // Authentication
  static const String authSignIn = 'auth.sign_in';
  static const String authSignUp = 'auth.sign_up';
  static const String authEmail = 'auth.email';
  static const String authPassword = 'auth.password';
  static const String authConfirmPassword = 'auth.confirm_password';
  static const String authPhone = 'auth.phone';
  static const String authVerifyPhone = 'auth.verify_phone';
  static const String authOtpSent = 'auth.otp_sent';
  static const String authEnterOtp = 'auth.enter_otp';
  static const String authName = 'auth.name';
  static const String authBirthday = 'auth.birthday';
  static const String authForgotPassword = 'auth.forgot_password';
  static const String authCreateAccount = 'auth.create_account';
  static const String authSignInButton = 'auth.sign_in_button';
  static const String authSignUpButton = 'auth.sign_up_button';
  static const String authSignOut = 'auth.sign_out';
  static const String authMustBe21 = 'auth.must_be_21';
  static const String authVerifyAge = 'auth.verify_age';

  // Messages
  static const String mapSearchConversations = 'map.search_conversations';
  static const String mapNoMessages = 'map.no_messages';
  static const String mapStartChatting = 'map.start_chatting';
  static const String mapSwarmChats = 'map.swarm_chats';
  static const String mapDirectMessages = 'map.direct_messages';

  // Swarms
  static const String swarmsTitle = 'swarms.title';
  static const String swarmsSubtitle = 'swarms.subtitle';
  static const String swarmsAllSwarms = 'swarms.all_swarms';
  static const String swarmsMySwarms = 'swarms.my_swarms';
  static const String swarmsLoading = 'swarms.loading';
  static const String swarmsEmptyAll = 'swarms.empty_all';
  static const String swarmsEmptyMine = 'swarms.empty_mine';
  static const String swarmsCreateFirst = 'swarms.create_first';
  static const String swarmsCreateButton = 'swarms.create_button';
  static const String swarmsActive = 'swarms.active';
  static const String swarmsManage = 'swarms.manage';
  static const String swarmsJoin = 'swarms.join';
  static const String swarmsMessageMembers = 'swarms.message_members';
  static const String swarmsShare = 'swarms.share';
  static const String swarmsCancel = 'swarms.cancel';
  static const String swarmsStartTime = 'swarms.start_time';
  static const String swarmsEndTime = 'swarms.end_time';
  static const String swarmsMaxAttendees = 'swarms.max_attendees';
  static const String swarmsDescription = 'swarms.description';

  // Settings
  static const String settingsTitle = 'settings.title';
  static const String settingsAccount = 'settings.account';
  static const String settingsSupport = 'settings.support';
  static const String settingsPreferences = 'settings.preferences';
  static const String settingsProfile = 'settings.profile';
  static const String settingsNotifications = 'settings.notifications';
  static const String settingsPrivacy = 'settings.privacy';
  static const String settingsHelp = 'settings.help';
  static const String settingsSafety = 'settings.safety';
  static const String settingsDarkMode = 'settings.dark_mode';
  static const String settingsDarkModeDesc = 'settings.dark_mode_desc';
  static const String settingsMetricUnits = 'settings.metric_units';
  static const String settingsUsingKm = 'settings.using_km';
  static const String settingsUsingMiles = 'settings.using_miles';
  static const String settingsVersion = 'settings.version';
  static const String settingsMadeWith = 'settings.made_with';

  // Profile
  static const String profileTitle = 'profile.title';
  static const String profileTonightStatus = 'profile.tonight_status';
  static const String profileChangeButton = 'profile.change_button';
  static const String profileGoingOut = 'profile.going_out';
  static const String profileMaybe = 'profile.maybe';
  static const String profileStayingIn = 'profile.staying_in';
  static const String profileNotSet = 'profile.not_set';
  static const String profileLetOthersKnow = 'profile.let_others_know';
  static const String profileAboutMe = 'profile.about_me';
  static const String profileMyVibes = 'profile.my_vibes';
  static const String profileFavoriteDrinks = 'profile.favorite_drinks';
  static const String profileInterests = 'profile.interests';
  static const String profileMoreAboutMe = 'profile.more_about_me';
  static const String profileFunFact = 'profile.fun_fact';
  static const String profileKaraokeSong = 'profile.karaoke_song';
  static const String profileIdealNight = 'profile.ideal_night';
  static const String profileFirstDrink = 'profile.first_drink';
  static const String profileConnectWithMe = 'profile.connect_with_me';
  static const String profileInstagram = 'profile.instagram';
  static const String profileSpotify = 'profile.spotify';
  static const String profileNotFound = 'profile.not_found';
  static const String profileSetupIncomplete = 'profile.setup_incomplete';
  static const String profileCompleteSetup = 'profile.complete_setup';
  static const String profileLoading = 'profile.loading';

  // Payments
  static const String paymentsTitle = 'payments.title';
  static const String paymentsSettings = 'payments.settings';
  static const String paymentsSend = 'payments.send';
  static const String paymentsReceive = 'payments.receive';
  static const String paymentsAmount = 'payments.amount';
  static const String paymentsNote = 'payments.note';
  static const String paymentsConfirm = 'payments.confirm';
  static const String paymentsCancel = 'payments.cancel';
  static const String paymentsSuccess = 'payments.success';
  static const String paymentsError = 'payments.error';
  static const String paymentsVenmoSetup = 'payments.venmo_setup';
  static const String paymentsLinkVenmo = 'payments.link_venmo';

  // Gifts
  static const String giftsTitle = 'gifts.title';
  static const String giftsInbox = 'gifts.inbox';
  static const String giftsSend = 'gifts.send';
  static const String giftsSent = 'gifts.sent';
  static const String giftsReceived = 'gifts.received';
  static const String giftsNoGifts = 'gifts.no_gifts';
  static const String giftsCatalog = 'gifts.catalog';
  static const String giftsPrice = 'gifts.price';
  static const String giftsPurchase = 'gifts.purchase';
  static const String giftsSendToFriend = 'gifts.send_to_friend';

  // Music
  static const String musicShare = 'music.share';
  static const String musicSearch = 'music.search';
  static const String musicPlaying = 'music.playing';
  static const String musicArtist = 'music.artist';
  static const String musicPlatform = 'music.platform';

  // Common
  static const String commonSave = 'common.save';
  static const String commonCancel = 'common.cancel';
  static const String commonDelete = 'common.delete';
  static const String commonEdit = 'common.edit';
  static const String commonDone = 'common.done';
  static const String commonNext = 'common.next';
  static const String commonBack = 'common.back';
  static const String commonClose = 'common.close';
  static const String commonLoading = 'common.loading';
  static const String commonError = 'common.error';
  static const String commonSuccess = 'common.success';
  static const String commonConfirm = 'common.confirm';
  static const String commonSearch = 'common.search';
  static const String commonFilter = 'common.filter';
  static const String commonSort = 'common.sort';

  // Validation
  static const String validationRequired = 'validation.required';
  static const String validationInvalidEmail = 'validation.invalid_email';
  static const String validationPasswordMismatch = 'validation.password_mismatch';
  static const String validationMinLength = 'validation.min_length';
  static const String validationInvalidPhone = 'validation.invalid_phone';

  // Location
  static const String locationNearby = 'location.nearby';
  static const String locationMilesAway = 'location.miles_away';
  static const String locationKmAway = 'location.km_away';

  // Weather
  static const String weatherTitle = 'weather.title';
  static const String weatherTemperature = 'weather.temperature';
  static const String weatherCondition = 'weather.condition';

  // Transport
  static const String transportUber = 'transport.uber';
  static const String transportLyft = 'transport.lyft';
  static const String transportGetRide = 'transport.get_ride';
}
