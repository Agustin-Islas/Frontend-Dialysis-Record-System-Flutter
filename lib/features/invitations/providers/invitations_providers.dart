import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_dialysis_record/core/providers/providers.dart';
import 'package:frontend_dialysis_record/features/invitations/models/invitation_dto.dart';

final myDoctorInvitationsProvider =
    FutureProvider.autoDispose<List<InvitationDto>>((ref) async {
      final controller = ref.watch(invitationControllerProvider);
      return controller.getMyDoctorInvitations();
    });

final myPatientInvitationsProvider =
    FutureProvider.autoDispose<List<InvitationDto>>((ref) async {
      final controller = ref.watch(invitationControllerProvider);
      return controller.getMyPatientInvitations();
    });
