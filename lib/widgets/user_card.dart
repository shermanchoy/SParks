import 'package:flutter/material.dart';
import '../models/app_user.dart';

class UserCard extends StatelessWidget {
  final AppUser user;
  final AppUser? me;
  final VoidCallback onLike;

  const UserCard({
    super.key,
    required this.user,
    required this.onLike,
    this.me,
  });

  List<String> _commonGround(AppUser meUser, AppUser other) {
    final common = <String>[];

    if (meUser.school.isNotEmpty &&
        other.school.isNotEmpty &&
        meUser.school == other.school) {
      common.add('Same school');
    }

    if (meUser.intent.isNotEmpty &&
        other.intent.isNotEmpty &&
        meUser.intent == other.intent) {
      common.add('Same intent');
    }

    final a = meUser.interests.map((e) => e.toLowerCase().trim()).toSet();
    final b = other.interests.map((e) => e.toLowerCase().trim()).toSet();
    final shared = a.intersection(b);

    if (shared.isNotEmpty) {
      common.add('${shared.length} shared interests');
    }

    return common.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final meUser = me;
    final chips = (meUser == null) ? <String>[] : _commonGround(meUser, user);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFFFEBEE),
                child: Text(
                  (user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? 'Unnamed' : user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.school.isEmpty ? 'School not set' : user.school,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onLike,
                icon: const Icon(Icons.favorite),
                color: const Color(0xFFE53935),
                tooltip: 'Like',
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (chips.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((t) {
                return Chip(
                  label: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  backgroundColor: const Color(0xFFFFEBEE),
                  side: const BorderSide(color: Color(0xFFFFCDD2)),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          if (user.intent.isNotEmpty) ...[
            Text(
              'Looking for: ${user.intent}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],

          if (user.bio.isNotEmpty)
            Text(
              user.bio,
              style: const TextStyle(color: Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
