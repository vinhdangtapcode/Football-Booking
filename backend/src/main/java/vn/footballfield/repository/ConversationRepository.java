package vn.footballfield.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import vn.footballfield.entity.Conversation;

import java.util.List;
import java.util.Optional;

public interface ConversationRepository extends JpaRepository<Conversation, Long> {

    @Query("SELECT c FROM Conversation c WHERE c.user.id = :userId ORDER BY c.lastMessageTime DESC NULLS LAST")
    List<Conversation> findByUserId(@Param("userId") Integer userId);

    @Query("SELECT c FROM Conversation c WHERE c.owner.id = :ownerId ORDER BY c.lastMessageTime DESC NULLS LAST")
    List<Conversation> findByOwnerId(@Param("ownerId") Integer ownerId);

    @Query("SELECT c FROM Conversation c WHERE c.user.id = :userId AND c.owner.id = :ownerId")
    Optional<Conversation> findByUserIdAndOwnerId(@Param("userId") Integer userId, @Param("ownerId") Integer ownerId);

    @Query("SELECT c FROM Conversation c WHERE c.user.id = :userId AND c.owner.id = :ownerId AND c.field.id = :fieldId")
    Optional<Conversation> findByUserIdAndOwnerIdAndFieldId(@Param("userId") Integer userId,
            @Param("ownerId") Integer ownerId, @Param("fieldId") Integer fieldId);
}
