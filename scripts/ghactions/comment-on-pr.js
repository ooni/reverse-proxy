module.exports = async ({
  github,
  context,
  core,
  commentTitle,
  commentBody,
}) => {
  const body = `## ${commentTitle} 🤖
    ${commentBody}
    `;

  const prNumber = context.payload.pull_request.number;

  if (prNumber) {
    const { data: comments } = await github.rest.issues.listComments({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: prNumber,
    });
    const existingBotComment = comments.find((comment) => {
      return (
        comment.user.type === "Bot" &&
        comment.body.includes(`## ${commentTitle}`)
      );
    });

    if (existingBotComment) {
      await github.rest.issues.updateComment({
        issue_number: prNumber,
        owner: context.repo.owner,
        repo: context.repo.repo,
        comment_id: existingBotComment.id,
        body,
      });
    } else {
      await github.rest.issues.createComment({
        issue_number: prNumber,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body,
      });
    }
  }
};
