/// Every user-facing string in the project lives here — no literals in UI code.
abstract final class AppStrings {
  // ---- Spec §11 copy (use as-is) ----
  static const emptyChat = 'No messages yet. Start the conversation.';
  static const requestSent = 'Call requested. Waiting for trainer approval.';

  /// "Call approved for {date} {time}."
  static String approved(String date, String time) =>
      'Call approved for $date $time.';

  /// "Call request declined. Reason: {text}."
  static String declined(String text) =>
      'Call request declined. Reason: $text.';

  static const joinPrompt = 'Ready to join? Check mic and camera.';
  static const sessionEnded = 'Session saved to your logs.';

  // ---- Validation ----
  static const schedulePastError = 'Cannot schedule a call in the past';
  static const slotConflict = 'This slot is already booked';
  static const noteTooLong = 'Note must be 140 characters or less';

  // ---- Errors ----
  static const noConnection = 'No connection. Check that the token server is running.';
  static const genericError = 'Something went wrong. Please try again.';
  static const tokenFetchFailed = 'Could not get call access. Please retry.';
  static const roomCreateFailed = 'Could not create the call room. Please retry.';
  static const chatSendFailed = 'Message not sent. Tap to retry.';
  static const copyError = 'Copy error';
  static const retry = 'Retry';

  // ---- Auth / onboarding ----
  static const onboardTitle1 = 'Train with the best';
  static const onboardBody1 = 'Your personal trainer, one tap away.';
  static const onboardTitle2 = 'Chat & video call your coach';
  static const onboardBody2 = 'Plan sessions, track progress, stay accountable.';
  static const next = 'Next';
  static const getStarted = 'Get Started';
  static const createProfile = 'Create your profile';
  static const yourName = 'Your name';
  static const chooseTrainer = 'Choose your trainer';
  static const login = 'Login';
  static const email = 'Email';
  static const password = 'Password';
  static const memberBadge = 'Member';
  static const trainerBadge = 'Trainer';

  // ---- Home ----
  static const chatWithTrainer = 'Chat with Trainer';
  static const scheduleCall = 'Schedule Call';
  static const mySessions = 'My Sessions';
  static const members = 'Members';
  static const chats = 'Chats';
  static const requests = 'Requests';
  static const sessions = 'Sessions';

  // ---- Chat ----
  static const sayHi = 'Say hi';
  static const typeMessage = 'Type a message…';
  static const quickReply1 = 'Got it 👍';
  static const quickReply2 = 'Can we talk at 6?';
  static const quickReply3 = 'Share plan?';
  static const typing = 'typing…';

  // ---- Scheduler ----
  static const pickSlot = 'Pick a time slot';
  static const noteHint = 'Add a note (optional)';
  static const requestCall = 'Request Call';
  static const myRequests = 'My Requests';
  static String pendingApprovalBy(String trainer) =>
      'Pending approval by $trainer';
  static const approve = 'Approve';
  static const decline = 'Decline';
  static const declineReasonTitle = 'Reason for declining';
  static const declineReasonHint = 'Let the member know why';
  static const confirm = 'Confirm';
  static const cancel = 'Cancel';

  // ---- Calls ----
  static const upcomingCalls = 'Upcoming Calls';
  static const joinCall = 'Join Call';
  static const deviceCheck = 'Device Check';
  static const mute = 'Mute';
  static const unmute = 'Unmute';
  static const videoOn = 'Video On';
  static const videoOff = 'Video Off';
  static const flip = 'Flip';
  static const endCall = 'End';
  static const reconnecting = 'Reconnecting…';
  static const peerLeft = 'Peer left the call';

  // ---- Sessions ----
  static const filterAll = 'All';
  static const filterLast7 = 'Last 7 days';
  static const filterMonth = 'This Month';
  static const emptySessions = 'No sessions yet';
  static const scheduleFirstCall = 'Schedule your first call';
  static const rateSession = 'Rate session';
  static const addNote = 'Add a note (optional)';
  static const trainerQuickNotes = 'Quick notes';
  static const markComplete = 'Mark as complete';
  static const save = 'Save';
}
